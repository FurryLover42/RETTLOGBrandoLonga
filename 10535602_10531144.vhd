library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Prova Finale di Reti Logiche, AA 2019/2020
-- Componenti:
-- Stefano Dalla Longa,	codice persona 10535602
-- Nicolò Brandolese,	codice persona 10531144
-- modello fpga usato: xc7a200tfbg484-1

--entity declaration

entity project_reti_logiche is
	port(
		--input signals
		i_clk		: in std_logic;						--segnale di CLOCK generato dal tb
		i_start		: in std_logic;						--segnale di START generato dal tb
		i_rst		: in std_logic;						--segnale di RESET che inizializza la macchina pronta per ricevere il primo segnale di START
		i_data		: in std_logic_vector(7 downto 0);	--vettore proveniente dalla memoria in seguito a una richiesta di lettura
		--output signals
		o_address	:out std_logic_vector(15 downto 0);	--vettore di uscita contenente l'indirizzo dell'area di memoria desiderata
		o_done		:out std_logic;						--segnale di FINE ELABORAZIONE che comunica la fine dell'elaborazione e la scrittura del risultato in memoria
		o_en		:out std_logic;						--segnale di ENABLE da dover inviare alla memoria per poter comunicare (sia in lettura che in scrittura)
		o_we		:out std_logic;						--segnale di WRITE ENABLE da inviare alla memoria. Se = 1 richiede la scrittura, se = 0 richiede la lettura
		o_data		:out std_logic_vector(7 downto 0)	--vettore di uscita dal componente verso la memoria
	);
end project_reti_logiche;


--architecture declaration

architecture rtl of project_reti_logiche is

	--enumerazione degli stati della macchina. Per ora i nomi sono temporanei in attesa di nomi migliori, ma possiamo anche fregarcene e spiegare nella documentazione
	type state_type is (
		START_IDLE,			--si va in questo stato in seguito al segnale di reset a prescindere dallo stato attuale, e ci si resta finché start = 0
		WZ_READING_STATE,	--legge la i-esima working zone e va in WZ_CALC_STATE. Se invece non ci sono altre wz da leggere, va in NO_WZ_ENCODING
		WZ_CALC_STATE,		--controlla se l'address fa parte della i-esima wz. Se sì va in FOUND_WZ_ENCODING, se no count++ e va in WZ_READING_STATE
		FOUND_WZ_ENCODING,	--codifica la parola da scrivere nella ram in encoded_res, quindi va in writing state
		NO_WZ_ENCODING,		--codifica la parola da scrivere nella ram in encoded_res, quindi va in writing state. WHATIF: i due stati possono essere uniti
		WRITING_STATE,		--scrive nella ram il contenuto di encoded_res, quindi va in END_IDLE
		END_IDLE			--resta qui finché reset = 0
							--TODO: specifica il comportamento per start = 1 quando reset è rimasto a 0
	); --end state_type declaration
	
	--FSM signals
	signal current_state	: state_type;	--stato attuale
	signal next_state		: state_type;	--prossimo stato della FSM
	signal wz_counter		: unsigned(3 downto 0);	--contatore della working zone considerata (da 0 a 7, più bit di overflow). USE THIS
	--other internal signals
	signal base_address	: unsigned(7 downto 0);			--buffer interno per la memorizzazione dell'indirizzo da verificare USE THIS
	signal wz_address	: unsigned(7 downto 0);			--buffer interno per la working zone considerata al momento USE THIS
	signal calc_result	: unsigned(7 downto 0);			--codifica binaria dell'offset relativo alla working zone corretta USE THIS
	signal encoded_res	: std_logic_vector(7 downto 0);	--codifica finale da mandare come risposta alla ram

begin
	--questo processo propaga lo stato successivo e rende possibile un reset asincrono
	state_register : process(next_state, i_rst)
	begin
		if(i_rst = '1') then
			current_state <= START_IDLE;
		else
			current_state <= next_state;
		end if;
	end process;
	
	--questo processo stabilisce se il base address appartiene alla working zone e decide il next_state di conseguenza
	calc_process : process(i_clk, current_state, base_address, wz_address)
		variable completed : std_logic := '0';	--questa variabile serve a lasciare alla computazione un intero ciclo di clock
		                                        --TODO: sarebbe meglio un signal?
	begin
		if(current_state = WZ_CALC_STATE) then
			if(rising_edge(i_clk) and completed = '0') then
				calc_result <= base_address - wz_address;	--TODO: check this
				-- se non avviene overflow, si può determinare subito se base_address era nel range [wz_address, wz_address + offset]
				-- in caso di underflow, il MSB sara' 1, ed essendo unsigned risultera' sicuramente maggiore di 3, assumendo il comportamento desiderato.
				completed := '1';	-- in questo modo si ha a disposizione un intero ciclo di clock per la sottrazione
			elsif(rising_edge(i_clk) and completed = '1') then
				if(calc_result <= 3) then	--3 perché è l'offset. TODO: rendi offset una variabile globale (non so come si faccia in vhdl)
					next_state <= FOUND_WZ_ENCODING;
					completed := '0';	--serve solo nei casi di reset
				else
					completed  := '0';
					next_state <= WZ_READING_STATE;
				end if; --decisione in base al risultato
			end if; --decisione in base a clock e completed
		end if; --decisione in base allo stato
	end process;
	
	--questo processo codifica encoded_res
	found_wz_encode : process(i_clk, current_state, base_address, wz_address, calc_result, wz_counter)
		variable completed    : std_logic := '0';
	begin
		if(current_state = NO_WZ_ENCODING) then	--codifica nel caso in cui non è stata trovata nessuna working zone
			if(rising_edge(i_clk) and completed = '0') then
				encoded_res(7) <= '0';
				encoded_res(6 downto 0) <= std_logic_vector(base_address(6 downto 0));	--NOT SURE ABOUT THAT
				completed := '1';
			elsif(rising_edge(i_clk) and completed = '1') then
				next_state <= WRITING_STATE;
				completed := '0';
			end if; --decisione in base al clock
		elsif (current_state = FOUND_WZ_ENCODING) then --codifica nel caso in cui è stata trovata una working zone
			if(rising_edge(i_clk) and completed = '0') then
				encoded_res(7) <= '1';
				encoded_res(6 downto 4) <= std_logic_vector(wz_counter(2 downto 0));
				case calc_result(1 downto 0) is
					when "00" =>
						encoded_res(3 downto 0) <= "0001";
					when "01" =>
						encoded_res(3 downto 0) <= "0010";
					when "10" =>
						encoded_res(3 downto 0) <= "0100";
					when "11" =>
					    encoded_res(3 downto 0) <= "1000";
					when others => --impossible
					    encoded_res(3 downto 0) <= "XXXX";
				end case;
				completed := '1';
			elsif(rising_edge(i_clk) and completed = '1') then
				next_state <= WRITING_STATE;
				completed := '0';
			end if; --decisione in base al clock
		end if; --decisione in base allo stato
	end process;

end rtl;