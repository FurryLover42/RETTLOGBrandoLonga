library ieee;
use ieee.std_logic_1164.all;

--il programma è costituito da una finite state machine in grado di riconoscere la sequenza 1101.
--tale sequenza viene riconosciuta sul segnale di input ad ogni fronte di salita del clock.
--ogni volta che la sequenza compare, il segnale di output viene posto a 1 per tutta la durata del ciclo di clock
--c'è un segnale di reset asincrono: basta che si alzi più o meno in qualunque momento perché la macchina torni allo stato iniziale al prossimo ciclo di clock

entity fsm is port(
	
	--inputs
	input:	 in std_logic;
	clk:	 in std_logic;
	reset:	 in std_logic;
	
	--outputs
	output:	out std_logic);
	
end fsm;


architecture rtl of fsm is
	--nota: tecnicamente puoi chiamarla come vuoi, ma si chiama "rtl" (register-transfer-level) questa qua e "sim" quella del testbench
	type state_type is (S0, S1, S2, S3, S4); --cosi' non devi preoccuparti della rappresentazione interna
	signal current_state:	state_type;
	signal next_state:		state_type;
begin --begin architecture
	
	--state register: componente che scandisce lo stato in cui passare
	state_register: process(clk, reset)
	begin
		if(reset = '1') then
			current_state <= S0;
		elsif(rising_edge(clk)) then
		--alcuni scrivono elsif(clk'event and clk = '1'), ma stack overflow dice che producono casi diversi nel caso il clock vada da H a 1
			current_state <= next_state;
		end if;
	end process;
	
	state_calculator: process(current_state, input)
	begin
		case current_state is
			when S0 =>
				if input = '1' then
					next_state <= S1;
				else
					next_state <= S0;
				end if;
			when S1 =>
				if input = '1' then
					next_state <= S2;
				else
					next_state <= S0;
				end if;
			when S2 =>
				if input = '1' then
					next_state <= S2; --maybe useless, but I didn't want to leave it undefined
				else
					next_state <= S3;
				end if;
			when S3 =>
				if input = '1' then
					next_state <= S4;
				else
					next_state <= S0;
				end if;
			when S4 =>
				if input = '1' then
					next_state <= S2;
				else
					next_state <= S0;
				end if;
			when others => null;
		end case;
	end process;
	
	output_calculator: process(current_state) --moore machine: it depends only on current_state
	begin
		if current_state = S4 then
			output <= '1';
		else
			output <= '0';
		end if;
	end process;

end architecture rtl;
-- va bene anche solo end RTL;