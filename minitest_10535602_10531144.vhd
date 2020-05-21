library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--	The syntax for an entity with a port in VHDL is:
--	entity <entity_name> is
--	port(
--	    <entity_signal_name> : in|out|inout <signal_type>;
--	    ...
--	);
--	end entity;
--	
--	The syntax for instantiating such a module in another VHDL file is:
--	<label> : entity <library_name>.<entity_name>(<architecture_name>) port map(
--	    <entity_signal_name> => <local_signal_name>,
--	    ...
--	);
--	
--	The <label> can be any name, and it will show up in the hierarchy window in ModelSim.
--	The <library_name> for a module is set in the simulator, not in the VHDL code. By default every module is compiled into the work library.
--	The <entity_name> and <architecture_name> must match the module we are creating an instance of.
--	Finally, each of the entity signals must be mapped to a local signal name.

entity minitest is end minitest;

architecture sim of minitest is
	
	--output
	signal clock	: std_logic;
	signal start	: std_logic;
	signal reset	: std_logic;
	signal out_data	: std_logic_vector(7 downto 0);
	--input
	signal address	: std_logic_vector(15 downto 0);
	signal in_data	: std_logic_vector(7 downto 0);
	signal enable	: std_logic;
	signal write_en	: std_logic;
	signal done		: std_logic;

	--Dichiarazioni per clock
	constant CLK_WAIT : time := 50 ns;

	--Dichiarazioni simulazione RAM
	type ram_type is array (65535 downto 0) of std_logic_vector(7 downto 0);
	signal RAM : ram_type;

	--Dichiarazioni per test
	constant EXAMPLE    : integer   := 1; 
	signal   start_test : std_logic := '0';

begin
	
	--port mapping
	macchina : entity work.project_reti_logiche(rtl) port map(
		i_clk		=> clock,
		i_start		=> start,
		i_rst		=> reset,
		i_data		=> out_data,

		o_address	=> address,
		o_done		=> done,
		o_en		=> enable,
		o_we		=> write_en,
		o_data		=> in_data);
		
	--Clock
	clock : process is	--clock process. La specifica ci concede un clock di periodo 100 ns
	begin
		clock <= '0';
		wait for CLK_WAIT;
		clock <= '1';
		wait for CLK_WAIT;
	end process;
		
	--RAM
	ram : process(clock)
	begin
		if rising_edge(clock) then
			if enable = '1' then
				if write_en = '1' then
					RAM(conv_integer(address)) <= in_data;
					out_data <= in_data;
				else
					out_data <= RAM(conv_integer(address));
				end if;
			end if;
		end if;
	end process;

	--Processo di selezione del test
	selectExample : process()
	begin
		
		case( EXAMPLE ) is
		
			when 1 =>
			
			RAM(0) <= 04;
			RAM(1) <= 13;
			RAM(2) <= 22;
			RAM(3) <= 31;
			RAM(4) <= 37;
			RAM(5) <= 45;
			RAM(6) <= 77;
			RAM(7) <= 91;
			RAM(8) <= 42;
			start_test <= '1';

			when others =>

		end case;

		wait;

	end process ;

	--Processo di esecuzione di test
	performTest : process(start_test)
	begin
		
		if(start_test = '1') then

			start <= '1';

			wait for done;

			report RAM(9);
			start <= '0';

		end if;

	end process ;

end architecture sim;