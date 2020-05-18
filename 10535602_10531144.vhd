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
	signal current_state	: state_type;				      --stato attuale
	signal next_state		: state_type;				      --prossimo stato della FSM
	signal wz_counter		: unsigned(3 downto 0) := "0000"; --contatore della working zone considerata (da 0 a 7, più bit di overflow). USE THIS
	--other internal signals
	signal base_address		: unsigned(7 downto 0);			--buffer interno per la memorizzazione dell'indirizzo da verificare USE THIS
	signal wz_address		: unsigned(7 downto 0);			--buffer interno per la working zone considerata al momento USE THIS
	signal calc_result		: unsigned(7 downto 0);			--codifica binaria dell'offset relativo alla working zone corretta USE THIS
	signal encoded_res		: std_logic_vector(7 downto 0);	--codifica finale da mandare come risposta alla ram

	--Dichiarazioni per Read Address
	--Dichiarazioni per la sub-FSM
	type t_ra_state is (
		RA_WAIT_FOR_START,   --Aspetta segnale i_start
		RA_ASK_ADDRESS,      --Richiedi indirizzo a RAM
		RA_READ_ADDRESS,     --Leggi indirizzo da RAM
		RA_ASK_WZ,           --Richiedi indirizzo base WZ a RAM
		RA_READ_WZ,          --Leggi indirizzo base WZ da RAM
		RA_WAIT_FOR_RESULTS, --Aspetta che processo di elaborazione dia successo o fallimento
		RA_DONE              --My work here is done
	);
	signal ra_current_state  : t_ra_state := RA_WAIT_FOR_START; --Stato attuale della sub-FSM
	signal ra_next_state     : t_ra_state;                      --Stato prossimo della sub-FSM

	--Dichiarazioni per comunicare con operazioni di controllo
	signal ra_result_found   : std_logic := '0'; --Alzare a 1 se l'operazione di controllo è terminata
	signal ra_result_success : std_logic := '0'; --Alzare a 1 se l'operazione di controllo a trovato risultato positivo
	signal ra_result_failure : std_logic := '0'; --Alzare a 1 se l'operazione di controllo a trovato risultato negativo

	--Dichiarazioni costanti
	constant BASEADD    : unsigned(15 downto 0) := x"0000";
	constant BASEOFFSET : integer := 8;
	constant ADDOFF     : unsigned(3 downto 0) := x"8";

	--Utilizzo RAM
	--Dichiarazioni constanti
	constant RESULTOFF : unsigned(3 downto 0) := x"9";

	--Dichiarazioni funzioni
	function calculateAddress(offset :unsigned)
	return std_logic_vector is
	begin
	
		return std_logic_vector(BASEADD + BASEOFFSET * offset);

	end function;

begin
	--questo processo propaga lo stato successivo e rende possibile un reset asincrono
	state_register : process(i_rst, i_clk, base_address, wz_address, calc_result, wz_counter, current_state)
	begin
		if(i_rst = '1') then
			current_state <= START_IDLE;
		elsif(rising_edge(i_clk)) then
			current_state <= next_state;
		end if;
	end process;
	
	calc_process : process(i_start, current_state, base_address, wz_address, calc_result, wz_counter)
		
		variable completed_verify	: std_logic := '0';	--per la computazione della verifica della working zone
		variable completed_encoding : std_logic := '0';	--per la codifica del segnale di uscita, sia nel caso NO_WZ sia nel FOUND_WZ
		constant MAX_OFFSET			: integer	:= 3;	--affinché il base address appartenga alla working zone, la differenza massima è 3

	begin
		case current_state is
			
			-- rimane in questo stato fino al segnale di start
			when START_IDLE =>
				if(i_start = '1') then
					next_state <= WZ_READING_STATE;
				else
					--reset dei segnali
					o_done 		<= '0';
					o_data		<= (others => '0');
					wz_counter	<= "0000";
				end if;
				
			-- stabilisce se il base address appartiene alla working zone contenuta in wz_address
			when WZ_CALC_STATE =>

				if(completed_verify = '0') then
					calc_result <= base_address - wz_address;	--TODO: check this
						-- se non avviene underflow, si può determinare subito se base_address era nel range [wz_address, wz_address + offset]
						-- in caso di underflow, il MSB sara' 1, ed essendo unsigned risultera' sicuramente maggiore di 3, assumendo il comportamento desiderato.
					completed_verify := '1';	-- in questo modo si ha a disposizione un intero ciclo di clock per la sottrazione
				elsif(completed_verify = '1') then
					if(calc_result <= MAX_OFFSET) then	--se è vero, il base address fa parte della working zone, e calc_result contiene il suo offset
						next_state <= FOUND_WZ_ENCODING;
						ra_result_success <= '1';
						completed_verify := '0';    --serve solo nei casi di reset
					else
						completed_verify := '0';
						ra_result_failure <= '1';
						next_state <= WZ_READING_STATE;
					end if; --decisione in base al risultato
					ra_result_found <= '1';
				end if;	--decisione in base a completed_verify


			-- codifica il segnale di uscita, nel caso in cui il base address non appartenga a nessuna working zone
			when NO_WZ_ENCODING =>

					if(completed_encoding = '0') then
						encoded_res(7) <= '0';
						encoded_res(6 downto 0) <= std_logic_vector(base_address(6 downto 0));	--NOT SURE ABOUT THAT
						completed_encoding := '1';
					elsif(completed_encoding = '1') then
						next_state <= WRITING_STATE;
						completed_encoding := '0';
					end if; --decisione in base a completed_encoding					


			-- codifica il segnale di uscita, nel caso in cui il base address appartenga all'i-esima working zone.
			-- in questo caso, il valore di i è contenuto nel vettore wz_counter, e l'offset nel vettore calc_result
			when FOUND_WZ_ENCODING =>

					if(completed_encoding = '0') then
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
							when others => --condizione impossibile
								encoded_res(3 downto 0) <= "XXXX";
						end case;
						completed_encoding := '1';
					elsif(completed_encoding = '1') then
						next_state <= WRITING_STATE;
						completed_encoding := '0';
					end if; --decisione in base a completed_encoding					

					
			when others =>
				--not programmed yet, add here the other states, but leave "when others =>" or the compiler will complain
			end case; --decisione in base allo stato
	end process;

	--Processi di read address
	ra_state_register : process( i_clk, i_rst, i_start, current_state)
	begin
		
		--Azioni di reset per i processi di read address vanno qui
		if(i_rst = '1') then

			ra_current_state <= RA_WAIT_FOR_START;

		elsif(rising_edge(i_clk) and current_state = WZ_READING_STATE) then
			
			ra_current_state <= ra_next_state;		

		end if ;

	end process ; -- ra_state_register

	ra_next_state_logic : process(ra_current_state)
	begin

		case(ra_current_state) is

			when RA_WAIT_FOR_START =>
				if (i_start = '1') then
					ra_next_state <= RA_ASK_ADDRESS;
				else
					ra_next_state <= RA_WAIT_FOR_START;
				end if ;
			
			when RA_ASK_ADDRESS =>
				ra_next_state <= RA_READ_ADDRESS;

			when RA_READ_ADDRESS =>
				ra_next_state <= RA_ASK_WZ;	

			when RA_ASK_WZ =>
				ra_next_state <= RA_READ_WZ;

			when RA_READ_WZ =>
				ra_next_state <= RA_WAIT_FOR_RESULTS;

			when RA_WAIT_FOR_RESULTS =>
				if(ra_result_found = '1') then
					if(ra_result_success = '1') then
						ra_next_state <= RA_DONE;
					elsif(ra_result_failure = '1') then
						if(wz_counter = 7) then
							ra_next_state <= RA_DONE;
						else
							--wz_counter <= wz_counter + 1; --this is done by calc_process
							ra_next_state <= RA_ASK_WZ;	
						end if ;
					end if;
				else
					ra_next_state <= RA_WAIT_FOR_RESULTS;
				end if;
		
			when others =>
				ra_next_state <= RA_DONE;

		end case ;

	end process ; -- ra_next_state_logic

	--Processo di comunicazione con RAM, un ciclo di clock deve essere abbastanza per leggere/scrivere un dato
	speak_with_RAM : process( i_clk, current_state, ra_current_state, wz_counter, i_data)
	begin
	
		case( current_state ) is
		
			when START_IDLE =>
				o_en <= '0';
				o_we <= '0';
				o_address <= x"0000";
		
			when WZ_READING_STATE =>
				o_en <= '0';
				o_we <= '0';
				o_address <= x"0000";
				
				case( ra_current_state ) is
				
					when RA_ASK_ADDRESS =>
						o_address <= calculateAddress(ADDOFF);
						o_en 	  <= '1';
				
					when RA_ASK_WZ =>
						o_address <= calculateAddress(wz_counter);
						o_en 	  <= '1';

					when RA_READ_ADDRESS =>
						base_address <= unsigned(i_data);

					when RA_READ_WZ =>
						wz_address <= unsigned(i_data);

					when others =>

				end case ;
			
			when WRITING_STATE =>
				o_en      <= '1';
				o_we      <= '1';
				o_address <= calculateAddress(RESULTOFF);
				o_data    <= encoded_res;

			when others =>
		
		end case ;

	end process ; -- read_from_RAM
	
end rtl;