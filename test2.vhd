library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity testing is
end testing;

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
	signal number_of_test	: integer := 1;
	constant total_test		: integer := 24;	--se vuoi aggiungere o eliminare test, modifica questo numero

    --Dichiarazione di funzioni
	function assign(number : integer) return std_logic_vector is
	begin

		return std_logic_vector(to_unsigned(number, 8));

	end function;

component project_reti_logiche is
port (
      i_clk         : in  std_logic;
      i_start       : in  std_logic;
      i_rst         : in  std_logic;
      i_data        : in  std_logic_vector(7 downto 0);
      o_address     : out std_logic_vector(15 downto 0);
      o_done        : out std_logic;
      o_en          : out std_logic;
      o_we          : out std_logic;
      o_data        : out std_logic_vector (7 downto 0)
      );
end component project_reti_logiche;

begin	--begin architecture

	--port mapping
	macchina : project_reti_logiche port map(
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

				when 14 =>

				RAM(0) <= assign(58);
				RAM(1) <= assign(70);
				RAM(2) <= assign(80);
				RAM(3) <= assign(44);
				RAM(4) <= assign(73);
				RAM(5) <= assign(1);
				RAM(6) <= assign(19);
				RAM(7) <= assign(22);
				RAM(8) <= assign(94);--miss
				--expected 0101.1110 5e 94

				when 15 =>

				RAM(0) <= assign(79);
				RAM(1) <= assign(3);
				RAM(2) <= assign(72);
				RAM(3) <= assign(79);
				RAM(4) <= assign(7);
				RAM(5) <= assign(66);
				RAM(6) <= assign(75);
				RAM(7) <= assign(0);--hit
				RAM(8) <= assign(0);
				--expected 1111.0001 f1 241

				when 16 =>

				RAM(0) <= assign(23);
				RAM(1) <= assign(17);
				RAM(2) <= assign(92);
				RAM(3) <= assign(5);--hit
				RAM(4) <= assign(9);
				RAM(5) <= assign(9);
				RAM(6) <= assign(21);
				RAM(7) <= assign(40);
				RAM(8) <= assign(7);
				--expected b4 180

				when 17 =>

				RAM(0) <= assign(35);
				RAM(1) <= assign(85);
				RAM(2) <= assign(44);
				RAM(3) <= assign(22);
				RAM(4) <= assign(22);
				RAM(5) <= assign(39);
				RAM(6) <= assign(83);
				RAM(7) <= assign(110);
				RAM(8) <= assign(33);--miss
				--expected 0010.0001 21 33

				when 18 =>

				RAM(0) <= assign(79);
				RAM(1) <= assign(125);
				RAM(2) <= assign(90);
				RAM(3) <= assign(83);
				RAM(4) <= assign(88);
				RAM(5) <= assign(85);
				RAM(6) <= assign(97);
				RAM(7) <= assign(93);
				RAM(8) <= assign(0);--miss
				--expected 0000.0000 00 0

				when 19 =>

				RAM(0) <= assign(21);
				RAM(1) <= assign(117);--hit
				RAM(2) <= assign(4);
				RAM(3) <= assign(42);
				RAM(4) <= assign(24);
				RAM(5) <= assign(96);
				RAM(6) <= assign(85);
				RAM(7) <= assign(80);
				RAM(8) <= assign(120);
				--expected 1001.1000 98 152

				when 20 =>

				RAM(0) <= assign(58);
				RAM(1) <= assign(99);
				RAM(2) <= assign(94);
				RAM(3) <= assign(87);
				RAM(4) <= assign(109);
				RAM(5) <= assign(90);
				RAM(6) <= assign(112);
				RAM(7) <= assign(65);
				RAM(8) <= assign(127);--miss
				--expected 0111.1111 7f 127

				when 21 =>

				RAM(0) <= assign(83);--hit
				RAM(1) <= assign(94);
				RAM(2) <= assign(26);
				RAM(3) <= assign(32);
				RAM(4) <= assign(18);
				RAM(5) <= assign(44);
				RAM(6) <= assign(35);
				RAM(7) <= assign(84);
				RAM(8) <= assign(84);
				--expected 1000.0010 82 130

				when 22 =>

				RAM(0) <= assign(17);
				RAM(1) <= assign(111);
				RAM(2) <= assign(78);
				RAM(3) <= assign(36);
				RAM(4) <= assign(83);--hit
				RAM(5) <= assign(68);
				RAM(6) <= assign(35);
				RAM(7) <= assign(64);
				RAM(8) <= assign(85);
				--expected 1100.0100 c4 196

				when 23 =>

				RAM(0) <= assign(35);
				RAM(1) <= assign(30);
				RAM(2) <= assign(47);
				RAM(3) <= assign(65);
				RAM(4) <= assign(25);
				RAM(5) <= assign(100);
				RAM(6) <= assign(8);
				RAM(7) <= assign(105);
				RAM(8) <= assign(6);--miss
				--expected 0000.0110 06 6

				when 24 =>

				RAM(0) <= assign(124);
				RAM(1) <= assign(13);
				RAM(2) <= assign(30);
				RAM(3) <= assign(24);
				RAM(4) <= assign(46);
				RAM(5) <= assign(93);
				RAM(6) <= assign(109);--hit
				RAM(7) <= assign(28);
				RAM(8) <= assign(110);
				--expected 1110.0010 e2 226

				when others =>	--impossible

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
		wait for 200 ns;
		
		start <= '0';
		
		case(number_of_test) is
			when 1 =>
				assert false report "test " & integer'image(number_of_test) & ": RAM(9) = " & integer'image(to_integer(unsigned(RAM(9))));
			when 2 =>
				assert false report "test " & integer'image(number_of_test) & ": RAM(9) = " & integer'image(to_integer(unsigned(RAM(9))));
			when 3 =>
				assert false report "test " & integer'image(number_of_test) & ": RAM(9) = " & integer'image(to_integer(unsigned(RAM(9))));
			when 4 =>
				assert false report "test " & integer'image(number_of_test) & ": RAM(9) = " & integer'image(to_integer(unsigned(RAM(9))));
			when 5 =>
				assert false report "test " & integer'image(number_of_test) & ": RAM(9) = " & integer'image(to_integer(unsigned(RAM(9))));
			when 6 =>
				assert false report "test " & integer'image(number_of_test) & ": RAM(9) = " & integer'image(to_integer(unsigned(RAM(9))));
			when 7 =>
				assert false report "test " & integer'image(number_of_test) & ": RAM(9) = " & integer'image(to_integer(unsigned(RAM(9))));
			when 8 =>
				assert false report "test " & integer'image(number_of_test) & ": RAM(9) = " & integer'image(to_integer(unsigned(RAM(9))));
			when 9 =>
				assert false report "test " & integer'image(number_of_test) & ": RAM(9) = " & integer'image(to_integer(unsigned(RAM(9))));
			when 10 =>
				assert false report "test " & integer'image(number_of_test) & ": RAM(9) = " & integer'image(to_integer(unsigned(RAM(9))));
			when 11 =>
				assert false report "test " & integer'image(number_of_test) & ": RAM(9) = " & integer'image(to_integer(unsigned(RAM(9))));
			when 12 =>
				assert false report "test " & integer'image(number_of_test) & ": RAM(9) = " & integer'image(to_integer(unsigned(RAM(9))));
			when 13 =>
				assert false report "test " & integer'image(number_of_test) & ": RAM(9) = " & integer'image(to_integer(unsigned(RAM(9))));
			when 14 =>
				assert false report "test " & integer'image(number_of_test) & ": RAM(9) = " & integer'image(to_integer(unsigned(RAM(9))));
			when 15 =>
				assert false report "test " & integer'image(number_of_test) & ": RAM(9) = " & integer'image(to_integer(unsigned(RAM(9))));
			when 16 =>
				assert false report "test " & integer'image(number_of_test) & ": RAM(9) = " & integer'image(to_integer(unsigned(RAM(9))));
			when 17 =>
				assert false report "test " & integer'image(number_of_test) & ": RAM(9) = " & integer'image(to_integer(unsigned(RAM(9))));
			when 18 =>
				assert false report "test " & integer'image(number_of_test) & ": RAM(9) = " & integer'image(to_integer(unsigned(RAM(9))));
			when 19 =>
				assert false report "test " & integer'image(number_of_test) & ": RAM(9) = " & integer'image(to_integer(unsigned(RAM(9))));
			when 20 =>
				assert false report "test " & integer'image(number_of_test) & ": RAM(9) = " & integer'image(to_integer(unsigned(RAM(9))));
			when 21 =>
				assert false report "test " & integer'image(number_of_test) & ": RAM(9) = " & integer'image(to_integer(unsigned(RAM(9))));
			when 22 =>
				assert false report "test " & integer'image(number_of_test) & ": RAM(9) = " & integer'image(to_integer(unsigned(RAM(9))));
			when 23 =>
				assert false report "test " & integer'image(number_of_test) & ": RAM(9) = " & integer'image(to_integer(unsigned(RAM(9))));
			when 24 =>
				assert false report "test " & integer'image(number_of_test) & ": RAM(9) = " & integer'image(to_integer(unsigned(RAM(9))));
				
										
			when others =>
				assert false report "impossible";
		end case;
		
		wait until done = '0';
		wait for 300 ns;
		
		if(number_of_test < total_test) then
			number_of_test <= number_of_test + 1; --esegue un nuovo test
		
		else
			assert false report "simulation ended" severity failure;
		end if;

	end process ; -- start_sim
	
	resetting: process
	begin
		reset <= '0';
		wait for 400 ns;
		reset <= '1';
		wait for 204 ns;
		reset <= '0';
		wait for 10 us;
		reset <= '1';
		wait for 35 ns;
		reset <= '0';
		wait;
	end process;
	

end architecture ; -- sim