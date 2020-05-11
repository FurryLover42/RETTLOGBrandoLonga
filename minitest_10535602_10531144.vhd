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
	
	--input
	signal clock	: std_logic;
	signal start	: std_logic;
	signal reset	: std_logic;
	signal in_data	: std_logic_vector(7 downto 0);
	--output
	signal address	: std_logic_vector(15 downto 0);
	signal out_data	: std_logic_vector(7 downto 0);
	signal enable	: std_logic;
	signal write_en	: std_logic;
	signal done		: std_logic;
begin
	
	--port mapping
	macchina : entity work.project_reti_logiche(rtl) port map(
		i_clk		=> clock,
		i_start		=> start,
		i_rst		=> reset,
		i_data		=> in_data,

		o_address	=> address,
		o_done		=> done,
		o_en		=> enable,
		o_we		=> write_en,
		o_data		=> out_data);
		
	process is	--clock process. La specifica ci concede un clock di periodo 100 ns
	begin
		clock <= '0';
		wait for 50 ns;
		clock <= '1';
		wait for 50 ns;
	end process;
			
	process is	--riscrivi questo per cambiare i segnali
	begin
		reset <= '1';
		wait for 10 ns;
		reset <= '0';
		wait for 123 ns;
		reset <= '1';
		wait for 94 ns;
		reset <= '0';
		wait;
	end process;

end architecture sim;