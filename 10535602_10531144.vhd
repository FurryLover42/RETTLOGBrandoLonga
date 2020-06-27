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
		ADD_WAIT_RESPONSE,	--stato di attesa per permettere alla RAM di processare la richiesta
		ADD_READING_STATE,  --legge l'indirizzo da codificare dalla RAM
		WZ_ASK_STATE,		--richiede l'i-esima wz alla RAM
		WZ_WAIT_RESPONSE,	--stato di attesa per permettere alla RAM di processare la richiesta
		WZ_READING_STATE,	--legge la i-esima working zone e va in WZ_CALC_STATE. Se invece non ci sono altre wz da leggere, va in NO_WZ_ENCODING
		WZ_CALC_STATE,		--calcola se l'address appartiene alla working zone corrente
		WZ_DECISION,		--in base a quanto fatto da WZ_CALC_STATE decide se passare a FOUND_WZ_ENCODING o WZ_ASK_STATE
		FOUND_WZ_ENCODING,	--codifica la parola da scrivere nella ram in encoded_res, quindi va in WRITING_STATE
		NO_WZ_ENCODING,		--codifica la parola da scrivere nella ram in encoded_res, quindi va in WRITING_STATE
		WRITING_STATE,		--scrive nella ram il contenuto di encoded_res, quindi va in WRITING_WAIT
		WRITING_WAIT,		--stato di attesa per permettere alla RAM di processare la richiesta, quindi va in DONE_WAIT
		DONE_IDLE,			--mantiene alto il segnale di done; quando il segnale di start si abbassa, va in END_IDLE
		END_IDLE			--resta qui finché i_start = '0', quindi torna in START_IDLE
	); --end state_type declaration
	
	--segnali della macchina a stati
	signal current_state	: state_type := START_IDLE;	    --stato attuale della FSM
	signal next_state		: state_type := START_IDLE;		--prossimo stato della FSM
	--registri interni
	signal wz_counter		: unsigned(15 downto 0) := x"0000";		--contatore della working zone considerata (da 0 a 7, più bit di overflow). 
	signal base_address		: unsigned(7 downto 0) := x"00";		--registro interno per la memorizzazione dell'indirizzo da verificare 
	signal wz_address		: unsigned(7 downto 0) := x"00";		--registro interno per la working zone considerata al momento 
	signal calc_result		: unsigned(7 downto 0) := x"00";		--registro interno della codifica binaria dell'offset relativo alla working zone corretta
	signal encoded_res		: unsigned(7 downto 0) := x"00";		--registro interno della codifica finale da mandare come risposta alla ram
	signal reset_request		: std_logic := '0';					--tiene conto di una richiesta di reset proveniente dalla RAM
	--segnali di modifica ai registri interni
	signal count_add_sig		: std_logic := '0';	--aumenta il valore del contatore di working zone wz_counter
	signal base_address_next	: unsigned(7 downto 0) := x"00";	--nuovo valore del registro base_address
	signal wz_address_next		: unsigned(7 downto 0) := x"00";	--nuovo valore del registro wz_address
	signal calc_result_next		: unsigned(7 downto 0) := x"00";	--nuovo valore del registro calc_result
	signal encoded_res_next		: unsigned(7 downto 0) := x"00";	--nuovo valore del registro encoded_res
	signal reset_request_next	: std_logic := '0';

	--Dichiarazioni costanti
	constant NOFWZ : unsigned(15 downto 0) := x"0008";	--numero di working zone

begin

	--questo processo aggiorna il contatore wz_counter e ne esegue il reset
	wz_counter_process : process(i_clk, count_add_sig, current_state)
	begin
		--reset
		if (current_state = ADD_ASK_STATE) then
			wz_counter <= x"0000";

		--aggiornamento del valore sul fronte di salita del clock
		elsif(falling_edge(i_clk)) then
			if(count_add_sig = '1') then
				wz_counter <= wz_counter + 1;
			else
				wz_counter <= wz_counter;
			end if;
		end if;
	end process;
	
	FF_saving : process(i_clk,
						base_address, wz_address,
						calc_result, encoded_res,
						reset_request)
	begin
		
		base_address	<= base_address;
		wz_address		<= wz_address;
		calc_result		<= calc_result;
		encoded_res		<= encoded_res;
		reset_request	<= reset_request;
		
		if(rising_edge(i_clk)) then
			
			base_address	<= base_address_next;
			wz_address		<= wz_address_next;
			calc_result		<= calc_result_next;
			encoded_res		<= encoded_res_next;
			reset_request	<= reset_request_next;

		end if; --clock
	end process;

	--questo processo tiene conto della richiesta di reset
	reset_handler : process(i_clk, i_rst, reset_request_next)
	begin
		reset_request_next <= reset_request_next;
		if(i_rst = '1') then
			reset_request_next <= '1';
		elsif(rising_edge(i_clk)) then
			reset_request_next <= '0';
		end if;
	end process;

	--questo processo propaga lo stato successivo e gestisce gli effetti del reset sulla macchina a stati
	state_register : process(i_clk)
	begin
		if(rising_edge(i_clk)) then
			if(reset_request = '1') then
				current_state <= START_IDLE;
			else
				current_state <= next_state;
			end if;--reset
		end if; --clock
	end process;

	--questo processo gestisce le operazioni interne che non si interfacciano con la RAM
	calc_process : process(current_state, i_start, base_address, wz_address, calc_result, wz_counter, encoded_res, reset_request, reset_request_next)

		constant MAX_OFFSET	: integer := 3;	--affinché il base address appartenga alla working zone, la differenza massima è 3

	begin
		case current_state is
			
			-- rimane in questo stato fino al segnale di start
			when START_IDLE =>
				--reset dei segnali
				count_add_sig	<= '0';
				o_done			<= '0';
				calc_result_next 	<= x"00";
				encoded_res_next	<= x"00";

				if(i_start = '1') then
					next_state <= ADD_ASK_STATE;
				else
					next_state <= START_IDLE;
				end if;
				
			--richiede indirizzo da codificare
			when ADD_ASK_STATE =>
				next_state <= ADD_WAIT_RESPONSE;

				count_add_sig	<= '0';
				o_done			<= '0';
				calc_result_next	<= calc_result;
				encoded_res_next	<= encoded_res;
				

			--pausa per un ciclo di clock
			when ADD_WAIT_RESPONSE =>
				next_state <= ADD_READING_STATE;

				count_add_sig	<= '0';
				o_done			<= '0';
				calc_result_next	<= calc_result;
				encoded_res_next	<= encoded_res;

			--Legge indirizzo da codificare dalla RAM
			when ADD_READING_STATE =>
				next_state <= WZ_ASK_STATE;

				count_add_sig	<= '0';
				o_done			<= '0';
				calc_result_next	<= calc_result;
				encoded_res_next	<= encoded_res;

			--richiede i-esima wz
			when WZ_ASK_STATE =>
				next_state <= WZ_WAIT_RESPONSE;

				count_add_sig	<= '0';
				o_done			<= '0';
				calc_result_next	<= calc_result;
				encoded_res_next	<= encoded_res;

			--pausa per un ciclo di clock
			when WZ_WAIT_RESPONSE =>
				next_state <= WZ_READING_STATE;

				count_add_sig	<= '0';
				o_done			<= '0';
				calc_result_next	<= calc_result;
				encoded_res_next	<= encoded_res;

			--Legge i-esima working zone dalla RAM
			when WZ_READING_STATE =>
				next_state <= WZ_CALC_STATE;

				count_add_sig	<= '0';
				o_done			<= '0';
				calc_result_next	<= calc_result;
				encoded_res_next	<= encoded_res;

			-- stabilisce se il base address appartiene alla working zone contenuta in wz_address
			when WZ_CALC_STATE =>

				calc_result_next <= base_address - wz_address;

				next_state <= WZ_DECISION;	--in questo modo, WZ_CALC_STATE ha a disposizione un intero ciclo di clock per la sottrazione dei due registri

				count_add_sig		<= '0';
				o_done				<= '0';
				encoded_res_next	<= encoded_res;
				

			--sceglie cosa fare in base al risultato dell'operazione eseguita in WZ_CALC_STATE
			when WZ_DECISION =>
				
				if(calc_result <= MAX_OFFSET) then	--se è vero, il base address fa parte della working zone, e calc_result contiene il suo offset
					next_state			<= FOUND_WZ_ENCODING;
					count_add_sig		<= '0';

				elsif(wz_counter >= NOFWZ) then	--se è vero, il base address non fa parte di nessuna working zone
					next_state			<= NO_WZ_ENCODING;
					count_add_sig		<= '0';
					
				else	--se sei qui, il base address non fa parte della wrking zone corrente, ma potrebbe far parte di una working zone futura
					next_state 			<= WZ_ASK_STATE;
					count_add_sig		<= '1';
				end if;

				o_done				<= '0';
				calc_result_next	<= calc_result;
				encoded_res_next	<= encoded_res;

			-- codifica il segnale di uscita, nel caso in cui il base address non appartenga a nessuna working zone
			when NO_WZ_ENCODING =>

				encoded_res_next(7) <= '0';
				encoded_res_next(6 downto 0) <= base_address(6 downto 0);
				next_state <= WRITING_STATE;

				--avoiding inferring latches
				count_add_sig	<= '0';
				o_done			<= '0';
				calc_result_next 	<= calc_result;

			-- codifica il segnale di uscita, nel caso in cui il base address appartenga all'i-esima working zone.
			-- in questo caso, il valore di i è contenuto nel vettore wz_counter, e l'offset nel vettore calc_result
			when FOUND_WZ_ENCODING =>
				encoded_res_next(7) <= '1';
				encoded_res_next(6 downto 4) <= wz_counter(2 downto 0);

				case calc_result(1 downto 0) is
					when "00" =>
						encoded_res_next(3 downto 0) <= "0001";
					when "01" =>
						encoded_res_next(3 downto 0) <= "0010";
					when "10" =>
						encoded_res_next(3 downto 0) <= "0100";
					when "11" =>
						encoded_res_next(3 downto 0) <= "1000";
					when others => --condizione impossibile
						encoded_res_next(3 downto 0) <= "0000";
				end case;
				next_state <= WRITING_STATE;

				count_add_sig	<= '0';
				o_done			<= '0';
				calc_result_next	<= calc_result;

			when WRITING_STATE =>
				next_state <= WRITING_WAIT;

				count_add_sig	<= '0';
				o_done 			<= '0';
				calc_result_next	<= calc_result;
				encoded_res_next	<= encoded_res;

			when WRITING_WAIT =>
				next_state <= DONE_IDLE;

				count_add_sig	<= '0';
				o_done 			<= '0';
				calc_result_next	<= calc_result;
				encoded_res_next	<= encoded_res;
			
			when DONE_IDLE =>
				if(reset_request = '1' or reset_request_next = '1')then
				--serve per evitare di alzare il segnale di done se per caso c'è un reset in corso
					o_done <= '0';
				else
					o_done <= '1';
				end if;
				
				if(i_start = '1') then
					next_state <= DONE_IDLE;
				else
					next_state <= END_IDLE;
				end if;

				count_add_sig	<= '0';
				calc_result_next	<= calc_result;
				encoded_res_next	<= encoded_res;

			when END_IDLE =>
				o_done <= '0';
				if(i_start = '0') then		--il modulo resta in questo stato finché i_start non viene abbassato
					next_state	<= END_IDLE;
				else	--il modulo può ricevere un nuovo segnale di start e ripartire con la fase di codifica
						--nota: non è necessario un reset, ma un segnale di reset è comunque gestibile
					next_state	<= START_IDLE;
				end if;

				count_add_sig	<= '0';
				calc_result_next	<= calc_result;
				encoded_res_next	<= encoded_res;
					
			when others =>	--condizione impossibile, perché tutti gli stati sono già stati presi in considerazione
				next_state		<= START_IDLE;
				count_add_sig	<= '0';
				o_done			<= '0';
				calc_result_next	<= calc_result;
				encoded_res_next	<= encoded_res;

			end case;
	end process;

	--Processo di comunicazione con RAM, un ciclo di clock deve essere abbastanza per leggere/scrivere un dato
	speak_with_RAM : process(current_state, wz_counter, i_data, encoded_res, base_address, wz_address)
	begin

		case( current_state ) is

			when ADD_ASK_STATE | ADD_WAIT_RESPONSE =>
				o_en		<= '1';
				o_we		<= '0';
				o_address	<= std_logic_vector(NOFWZ);
				o_data		<= (others => '0');

				base_address_next	<= base_address;
				wz_address_next		<= wz_address;

		
			when ADD_READING_STATE =>
				o_en		<= '0';
				o_we		<= '0';
				o_address	<= (others => '0');
				o_data		<= (others => '0');

				base_address_next	<= unsigned(i_data);	--modifica del FF
				wz_address_next		<= wz_address;

			when WZ_ASK_STATE | WZ_WAIT_RESPONSE =>
				o_en		<= '1';
				o_we		<= '0';
				o_address	<= std_logic_vector(wz_counter);
				o_data		<= (others => '0');

				base_address_next	<= base_address;
				wz_address_next		<= wz_address;
			
			when WZ_READING_STATE =>
				o_en		<= '0';
				o_we		<= '0';
				o_address	<= (others => '0');
				o_data		<= (others => '0');

				base_address_next	<= base_address;
				wz_address_next		<= unsigned(i_data);	--modifica del FF

			when WRITING_STATE | WRITING_WAIT =>
				o_en		<= '1';
				o_we		<= '1';
				o_address	<= std_logic_vector(NOFWZ + x"0001");
				o_data		<= std_logic_vector(encoded_res);

				base_address_next	<= base_address;
				wz_address_next		<= wz_address;

			when others =>
				o_en		<= '0';
				o_we		<= '0';
				o_address	<= (others => '0');
				o_data		<= (others => '0');

				base_address_next	<= base_address;
				wz_address_next		<= wz_address;

		end case ;

	end process ; -- speak_with_RAM
	
end rtl;