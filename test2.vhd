library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity testing is
end entity ; -- testing

architecture sim of testing is

	--output
	signal clock	: std_logic := '0';
	signal start	: std_logic;
	signal reset	: std_logic;
	signal out_data	: std_logic_vector(7 downto 0);
	--input
	signal address	: std_logic_vector(15 downto 0);
	signal in_data	: std_logic_vector(7 downto 0);
	signal enable	: std_logic;
	signal write_en	: std_logic;
	signal done		: std_logic;

	--Dichiarazioni clock
	constant CLOCK_PERIOD : time := 100 ns;

	--Dichiarazioni RAM
	constant RAM_SIZE      : integer := 65536;
	constant RAM_WORD_SIZE : integer := 8;

	type ram_type is array ((RAM_SIZE - 1) downto 0) of std_logic_vector((RAM_WORD_SIZE - 1) downto 0);

	signal RAM : ram_type := (others => (others => '0'));

	--Dichiarazioni segnali vari
	signal start_simulation : std_logic := '0';
	signal number_of_test : integer := 1;

    --Dichiarazione di funzioni
	function assign(number : integer) return std_logic_vector is
	begin

		return std_logic_vector(to_unsigned(number, 8));

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

	--clock
	clock_block : process
	begin
		
		wait for CLOCK_PERIOD/2;
		clock <= not clock;

	end process ; -- clock

	--RAM
	RAM_block : process(clock, start_simulation)
	begin
		
		if start_simulation = '1' then
			
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
				RAM(8) <= assign(42);--miss
				--expected 0010.1010 2a 42

				--Test per ogni caso di successo
				when 2 =>
				
				RAM(0) <= assign(04);--hit
				RAM(1) <= assign(13);
				RAM(2) <= assign(22);
				RAM(3) <= assign(31);
				RAM(4) <= assign(37);
				RAM(5) <= assign(45);
				RAM(6) <= assign(77);
				RAM(7) <= assign(91);
				RAM(8) <= assign(06);	
				--expected 1000.0100 84 132

				when 3 =>

				RAM(0) <= assign(04);
				RAM(1) <= assign(13);--hit
				RAM(2) <= assign(22);
				RAM(3) <= assign(31);
				RAM(4) <= assign(37);
				RAM(5) <= assign(45);
				RAM(6) <= assign(77);
				RAM(7) <= assign(91);
				RAM(8) <= assign(13);
				--expected 1001.0001 91 145

				when 4 =>

				RAM(0) <= assign(04);
				RAM(1) <= assign(13);
				RAM(2) <= assign(22);--hit
				RAM(3) <= assign(31);
				RAM(4) <= assign(37);
				RAM(5) <= assign(45);
				RAM(6) <= assign(77);
				RAM(7) <= assign(91);
				RAM(8) <= assign(23);
				--expected 1010.0010 a2 162

				when 5 =>

				RAM(0) <= assign(04);
				RAM(1) <= assign(13);
				RAM(2) <= assign(22);
				RAM(3) <= assign(31);--hit
				RAM(4) <= assign(37);
				RAM(5) <= assign(45);
				RAM(6) <= assign(77);
				RAM(7) <= assign(91);
				RAM(8) <= assign(33);
				--expected 1011.0100 b4 180

				when 6 =>

				RAM(0) <= assign(04);
				RAM(1) <= assign(13);
				RAM(2) <= assign(22);
				RAM(3) <= assign(31);
				RAM(4) <= assign(37);--hit
				RAM(5) <= assign(45);
				RAM(6) <= assign(77);
				RAM(7) <= assign(91);
				RAM(8) <= assign(40);
				--expected 1100.1000 c8 200

				when 7 =>

				RAM(0) <= assign(04);
				RAM(1) <= assign(13);
				RAM(2) <= assign(22);
				RAM(3) <= assign(31);
				RAM(4) <= assign(37);
				RAM(5) <= assign(45);--hit
				RAM(6) <= assign(77);
				RAM(7) <= assign(91);
				RAM(8) <= assign(45);
				--expected 1101.0001 d1 209

				when 8 =>

				RAM(0) <= assign(04);
				RAM(1) <= assign(13);
				RAM(2) <= assign(22);
				RAM(3) <= assign(31);
				RAM(4) <= assign(37);
				RAM(5) <= assign(45);
				RAM(6) <= assign(77);--hit
				RAM(7) <= assign(91);
				RAM(8) <= assign(78);
				--expected 1110.0010 e2 226

				when 9 =>

				RAM(0) <= assign(04);
				RAM(1) <= assign(13);
				RAM(2) <= assign(22);
				RAM(3) <= assign(31);
				RAM(4) <= assign(37);
				RAM(5) <= assign(45);
				RAM(6) <= assign(77);
				RAM(7) <= assign(91);--hit
				RAM(8) <= assign(93);
				--expected 1111.0100 f4 

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
				RAM(8) <= assign(42);--miss
				--expected 0010.1010 2a 42

				--Test di successo wz non crescenti
				when 11 =>

				RAM(1) <= assign(04);
				RAM(2) <= assign(13);--hit
				RAM(4) <= assign(22);
				RAM(5) <= assign(31);
				RAM(7) <= assign(37);
				RAM(0) <= assign(45);
				RAM(3) <= assign(77);
				RAM(6) <= assign(91);
				RAM(8) <= assign(14);
				--expected 1010.0010 a2 162

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
				RAM(8) <= assign(42);--miss
				--expected 0010.1010 2a 42

				--Test di successo wz ripetute
				when 13 =>

				RAM(0) <= assign(04);
				RAM(1) <= assign(04);
				RAM(2) <= assign(22);
				RAM(3) <= assign(22);
				RAM(4) <= assign(37);--hit
				RAM(5) <= assign(37);--this would also be a hit, but it doesn't matter
				RAM(6) <= assign(77);
				RAM(7) <= assign(77);
				RAM(8) <= assign(40);
				--expected 1100.1000 c8 200

				when others =>

			end case;

		end if;

		if rising_edge(clock) then
			if enable = '1' then
				if write_en = '1' then
					RAM(to_integer(unsigned(address))) <= in_data;
					out_data               <= in_data;
				else
					out_data <= RAM(to_integer(unsigned(address)));		
				end if ;
			end if ;
		end if ;

	end process ; -- RAM

	start_sim : process
	begin
		
		wait for 10 ns;

		start_simulation <= '1';

		wait for 10 ns;

		start_simulation <= '0';
		
		wait for 200 ns;
		
		start <= '1';

		wait until done = '1';
		
		start <= '0';
		
		wait until done = '0';
		
		if(number_of_test < 13) then
			number_of_test <= number_of_test + 1;
			wait for 100 ns;
			start <= '1';
		
		else
			assert false report "simulation ended";
		end if;

	end process ; -- start_sim
	
	resetting: process
	begin
		reset <= '0';
		wait for 400 ns;
		reset <= '1';
		wait for 102 ns;
		reset <= '0';
		wait for 10 us;
		reset <= '1';
		wait for 35 ns;
		reset <= '0';
		wait;
	end process;
	

end architecture ; -- sim