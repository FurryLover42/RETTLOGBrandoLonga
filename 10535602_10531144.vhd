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
		ADD_ASK_STATE,      --richiede l'indirizzo da codificare alla RAM
		ADD_READING_STATE,  --legge l'indirizzo da codificare dalla RAM
		WZ_ASK_STATE,		--richiede l'i-esima wz alla RAM
		WZ_READING_STATE,	--legge la i-esima working zone e va in WZ_CALC_STATE. Se invece non ci sono altre wz da leggere, va in NO_WZ_ENCODING
		WZ_CALC_STATE,		--calcola se l'address appartiene alla working zone corrente
		WZ_DECISION,		--in base a quanto fatto da WZ_CALC_STATE decide se passare all'encoding o richiedere una nuova working zone
		FOUND_WZ_ENCODING,	--codifica la parola da scrivere nella ram in encoded_res, quindi va in writing state
		NO_WZ_ENCODING,		--codifica la parola da scrivere nella ram in encoded_res, quindi va in writing state. WHATIF: i due stati possono essere uniti
		WRITING_STATE,		--scrive nella ram il contenuto di encoded_res, quindi va in END_IDLE
		END_IDLE			--resta qui finché reset = 0
							--TODO: specifica il comportamento per start = 1 quando reset è rimasto a 0
	); --end state_type declaration
	
	--FSM signals
	signal current_state	: state_type := START_IDLE;	      --stato attuale
	signal next_state		: state_type;				      --prossimo stato della FSM
	signal wz_counter		: unsigned(3 downto 0) := "0000"; --contatore della working zone considerata (da 0 a 7, più bit di overflow). 
	--other internal signals
	signal base_address		: unsigned(7 downto 0);			--buffer interno per la memorizzazione dell'indirizzo da verificare 
	signal wz_address		: unsigned(7 downto 0);			--buffer interno per la working zone considerata al momento 
	signal calc_result		: unsigned(7 downto 0);			--codifica binaria dell'offset relativo alla working zone corretta
	signal encoded_res		: std_logic_vector(7 downto 0);	--codifica finale da mandare come risposta alla ram

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
	state_register : process(i_rst, i_clk)
	begin
		if(i_rst = '1') then
			current_state <= START_IDLE;
		elsif(rising_edge(i_clk)) then
			current_state <= next_state;
		end if;
	end process;

	--questo processo gestisce le operazioni interne che non si interfacciano con la RAM
	calc_process : process(current_state, i_start, base_address, wz_address, calc_result, wz_counter, encoded_res) --TODO: Rimuovi segnali che non risvegliano questo processo

		constant MAX_OFFSET	: integer := 3;	--affinché il base address appartenga alla working zone, la differenza massima è 3

	begin
		case current_state is
			
			-- rimane in questo stato fino al segnale di start
			when START_IDLE =>
				--reset dei segnali
				wz_counter			<= "0000";
				o_done				<= '0';
				calc_result 		<= x"11";
				encoded_res			<= x"00";

				if(i_start = '1') then
					next_state <= ADD_ASK_STATE;
				else
					next_state <= START_IDLE;
				end if;

				--avoiding inferring latches
				wz_counter 			<= wz_counter;
				o_done 				<= '0';
				calc_result 		<= calc_result;
				encoded_res			<= encoded_res;					
				
			--richiede indirizzo da codificare
			when ADD_ASK_STATE =>
				next_state <= ADD_READING_STATE;

			--Legge indirizzo da codificare dalla RAM
			when ADD_READING_STATE =>
				next_state <= WZ_ASK_STATE;

			--richiede i-esima wz
			when WR_ASK_STATE =>
				next_state <= WZ_READING_STATE;

			--Legge i-esima working zone dalla RAM
			when WZ_READING_STATE =>
				next_state <= WZ_CALC_STATE;

			-- stabilisce se il base address appartiene alla working zone contenuta in wz_address
			when WZ_CALC_STATE =>

				calc_result <= base_address - wz_address;	--TODO: check this
					-- se non avviene underflow, si può determinare subito se base_address era nel range [wz_address, wz_address + offset]
					-- in caso di underflow, il MSB sara' 1, ed essendo unsigned risultera' sicuramente maggiore di 3, assumendo il comportamento desiderato.
				next_state <= WZ_DECISION;	--in questo modo, WZ_CALC_STATE ha a disposizione un intero ciclo di clock per la sottrazione dei due registri

				--avoiding inferring latches
				wz_counter 			<= wz_counter;
				o_done 				<= '0';
				encoded_res			<= encoded_res;
				

			--sceglie cosa fare in base al risultato dell'operazione eseguita in WZ_CALC_STATE
			when WZ_DECISION =>
				
				if(calc_result <= MAX_OFFSET) then	--se è vero, il base address fa parte della working zone, e calc_result contiene il suo offset
					next_state			<= FOUND_WZ_ENCODING;
					wz_counter			<= wz_counter;

				else
					next_state 			<= WZ_READING_STATE;
					wz_counter			<= wz_counter + 1;
				end if; --decisione in base al risultato

				--avoiding inferring latches
				wz_counter 			<= wz_counter;
				o_done 				<= '0';
				calc_result 		<= calc_result;
				encoded_res			<= encoded_res;

			-- codifica il segnale di uscita, nel caso in cui il base address non appartenga a nessuna working zone
			when NO_WZ_ENCODING =>

				encoded_res(7) <= '0';
				encoded_res(6 downto 0) <= std_logic_vector(base_address(6 downto 0));	--NOT SURE ABOUT THAT
				next_state <= WRITING_STATE;

				--avoiding inferring latches
				wz_counter 			<= wz_counter;
				o_done 				<= '0';
				calc_result 		<= calc_result;

			-- codifica il segnale di uscita, nel caso in cui il base address appartenga all'i-esima working zone.
			-- in questo caso, il valore di i è contenuto nel vettore wz_counter, e l'offset nel vettore calc_result
			when FOUND_WZ_ENCODING =>
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
				next_state <= WRITING_STATE;

				--avoiding inferring latches
				wz_counter 			<= wz_counter;
				o_done 				<= '0';
				calc_result 		<= calc_result;

			when END_IDLE =>
				if(i_start <= '1') then		--il modulo resta in questo stato finché i_start non viene abbassato
					o_done <= '1';
					next_state <= END_IDLE;
				else	--il modulo può ricevere un nuovo segnale di start e ripartire con la fase di codifica
						--nota: non è necessario un reset, ma un segnale di reset è comunque gestibile
					o_done <= '0';
					next_state <= START_IDLE;
				end if;

				--avoiding inferring latches
				wz_counter 			<= wz_counter;
				calc_result 		<= calc_result;
				encoded_res			<= encoded_res;
					
			when others =>
				-- gli altri stati possibili sono gestiti dal processo speak_with_ram
				--avoiding inferring latches
				encoded_res			<= encoded_res;
				wz_counter 			<= wz_counter;
				o_done 				<= '0';
				calc_result 		<= calc_result;

			end case; --case basato sullo stato corrente
	end process;

	--Processo di comunicazione con RAM, un ciclo di clock deve essere abbastanza per leggere/scrivere un dato
	speak_with_RAM : process( i_clk, current_state, wz_counter, i_data, encoded_res) --TODO: Rimuovere segnali che non risvegliano questo processo
	begin

		case( current_state ) is	

			when ADD_ASK_STATE =>
				o_en <= '1';
				o_we <= '0';
				o_address <= calculateAddress(ADDOFF);
		
			when ADD_READING_STATE =>
				o_en <= '0';
				o_we <= '0';
				o_address <= x"0000";
				base_address <= i_data;

			when WZ_ASK_STATE =>
				o_en	<= '1';
				o_we	<= '0';
				o_address <= calculateAddress(wz_counter);
			
			when WZ_READING_STATE =>
				o_en <= '0';
				o_we <= '0';
				o_address <= x"0000";
				wz_address <= i_data;

			when WRITING_STATE =>
				o_en      <= '1';
				o_we      <= '1';
				o_address <= calculateAddress(RESULTOFF);
				o_data    <= encoded_res;

			when others =>
				o_en	<= '0';
				o_we	<= '0';
				o_address <= x"0000";

		end case ;

	end process ; -- speak_with_RAM
	
end rtl;