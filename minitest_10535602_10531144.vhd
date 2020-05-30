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
	constant RAMWORDS : integer := 16;
	constant RAMSIZE  : integer := 8;

	type ram_type is array ((RAMWORDS - 1) downto 0) of std_logic_vector((RAMSIZE - 1) downto 0);
	signal RAM : ram_type;

	--Dichiarazioni per test
	signal number_of_test	: integer   := 0; 
	
	constant TOTAL : integer := 1;

	--Funzioni
	--Converte interi in std_logic_vectors
	function assign(number : integer) return std_logic_vector is
	begin

		return std_logic_vector(to_unsigned(number, 8));

	end function;

	--Converte gli indirizzi di RAM bit-by-bit in posizioni dell'array
	--La comunicazione avviene parola per parola quindi ogni indirizzo non multiplo di 8 viene arrotondato per difetto alla precedente parola
	function convert_to_RAM_position(number : std_logic_vector) return integer is
	begin

		return to_integer(unsigned(number)) / 8;

	end function;

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
	clock_proc : process is	--clock process. La specifica ci concede un clock di periodo 100 ns
	begin
		clock <= '0';
		wait for CLK_WAIT;
		clock <= '1';
		wait for CLK_WAIT;
	end process;
	
	--Reset
	reset_proc : process
	begin
		wait for 220 ns;
			reset <= '1';
		wait for 450 ns;
			reset <= '0';
		wait;
	end process;
		
	--RAM
	ram_proc : process(clock)
	begin
		if rising_edge(clock) then
			if enable = '1' then
				if write_en = '1' then
					RAM(convert_to_RAM_position(address)) <= std_logic_vector(unsigned(in_data));
					out_data <= in_data;
				else
					out_data <= RAM(convert_to_RAM_position(address));
				end if;
			end if;
		end if;
	end process;

	--Processo di selezione del test
	test_select : process(number_of_test) is
	begin
		
		case( number_of_test ) is
		
			--Test del caso di fallimento
			when 1 =>
			
			RAM(0) <= assign(04);
			RAM(1) <= assign(13);
			RAM(2) <= assign(22);
			RAM(3) <= assign(31);
			RAM(4) <= assign(37);
			RAM(5) <= assign(45);
			RAM(6) <= assign(77);
			RAM(7) <= assign(91);
			RAM(8) <= assign(42);

			--Test per ogni caso di successo
			when 2 =>
			
			RAM(0) <= assign(04);
			RAM(1) <= assign(13);
			RAM(2) <= assign(22);
			RAM(3) <= assign(31);
			RAM(4) <= assign(37);
			RAM(5) <= assign(45);
			RAM(6) <= assign(77);
			RAM(7) <= assign(91);
			RAM(8) <= assign(06);	

			when 3 =>

			RAM(0) <= assign(04);
			RAM(1) <= assign(13);
			RAM(2) <= assign(22);
			RAM(3) <= assign(31);
			RAM(4) <= assign(37);
			RAM(5) <= assign(45);
			RAM(6) <= assign(77);
			RAM(7) <= assign(91);
			RAM(8) <= assign(13);

			when 4 =>

			RAM(0) <= assign(04);
			RAM(1) <= assign(13);
			RAM(2) <= assign(22);
			RAM(3) <= assign(31);
			RAM(4) <= assign(37);
			RAM(5) <= assign(45);
			RAM(6) <= assign(77);
			RAM(7) <= assign(91);
			RAM(8) <= assign(23);

			when 5 =>

			RAM(0) <= assign(04);
			RAM(1) <= assign(13);
			RAM(2) <= assign(22);
			RAM(3) <= assign(31);
			RAM(4) <= assign(37);
			RAM(5) <= assign(45);
			RAM(6) <= assign(77);
			RAM(7) <= assign(91);
			RAM(8) <= assign(33);

			when 6 =>

			RAM(0) <= assign(04);
			RAM(1) <= assign(13);
			RAM(2) <= assign(22);
			RAM(3) <= assign(31);
			RAM(4) <= assign(37);
			RAM(5) <= assign(45);
			RAM(6) <= assign(77);
			RAM(7) <= assign(91);
			RAM(8) <= assign(40);

			when 7 =>

			RAM(0) <= assign(04);
			RAM(1) <= assign(13);
			RAM(2) <= assign(22);
			RAM(3) <= assign(31);
			RAM(4) <= assign(37);
			RAM(5) <= assign(45);
			RAM(6) <= assign(77);
			RAM(7) <= assign(91);
			RAM(8) <= assign(45);

			when 8 =>

			RAM(0) <= assign(04);
			RAM(1) <= assign(13);
			RAM(2) <= assign(22);
			RAM(3) <= assign(31);
			RAM(4) <= assign(37);
			RAM(5) <= assign(45);
			RAM(6) <= assign(77);
			RAM(7) <= assign(91);
			RAM(8) <= assign(78);

			when 9 =>

			RAM(0) <= assign(04);
			RAM(1) <= assign(13);
			RAM(2) <= assign(22);
			RAM(3) <= assign(31);
			RAM(4) <= assign(37);
			RAM(5) <= assign(45);
			RAM(6) <= assign(77);
			RAM(7) <= assign(91);
			RAM(8) <= assign(93);

			--Test di fallimento wz non crescenti
			when 10 =>

			RAM(1) <= assign(04);
			RAM(3) <= assign(13);
			RAM(5) <= assign(22);
			RAM(7) <= assign(31);
			RAM(2) <= assign(37);
			RAM(4) <= assign(45);
			RAM(6) <= assign(77);
			RAM(0) <= assign(91);
			RAM(8) <= assign(42);

			--Test di successo wz non crescenti
			when 11 =>

			RAM(1) <= assign(04);
			RAM(2) <= assign(13);
			RAM(4) <= assign(22);
			RAM(5) <= assign(31);
			RAM(7) <= assign(37);
			RAM(0) <= assign(45);
			RAM(3) <= assign(77);
			RAM(6) <= assign(91);
			RAM(8) <= assign(14);

			--Test di fallimento wz ripetute
			when 12 =>

			RAM(0) <= assign(04);
			RAM(1) <= assign(04);
			RAM(2) <= assign(22);
			RAM(3) <= assign(22);
			RAM(4) <= assign(37);
			RAM(5) <= assign(37);
			RAM(6) <= assign(77);
			RAM(7) <= assign(77);
			RAM(8) <= assign(42);

			--Test di successo wz ripetute
			when 13 =>

			RAM(0) <= assign(04);
			RAM(1) <= assign(04);
			RAM(2) <= assign(22);
			RAM(3) <= assign(22);
			RAM(4) <= assign(37);
			RAM(5) <= assign(37);
			RAM(6) <= assign(77);
			RAM(7) <= assign(77);
			RAM(8) <= assign(40);

			when others =>

		end case;

	end process ;

	--Processo di esecuzione di test
	test_exec : process()
	begin
		start <= '1';
		number_of_test <= number_of_test + 1;

		wait on done;

		report RAM(9);

		wait;

	end process ;

end architecture sim;