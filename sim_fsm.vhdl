library ieee;
use ieee.std.logic_1164.all;
use ieee.std.numeric_std.all;

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




entity fsm is	
end fsm;


architecture sim of fsm is

	signal input:	signal;
	signal clk:		signal;
	signal reset:	signal;
	signal output:	signal;

begin
	
	--port mapping
	finite_state_machine : entity work.fsm(rtl) port map(
		input	=> input;
		clk		=> clk;
		reset	=> reset;
		output	=> output);
	
	--clock process
	process is
	begin
		clk <= '0';
		wait for 10 ns;
		clk <= '1';
		wait for 10 ns;
	end process;
	
	--testbench process
	process is
	begin
		input <= '0';
		reset <= '1';
		wait for 8 ns;
		reset <= '0';
		input <= '1';
		wait for 45 ns;
		input <= '0';
		wait for 10 ns;
		input <= '1';
		wait;
		
	end process;
	

end architecture sim;
-- va bene anche solo end RTL;