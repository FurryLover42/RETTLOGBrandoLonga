library ieee
use ieee.std_logic_1164.all

entity read_address_test is
  port (
	i_clk  	  : in std_logic;                      --Clock
	i_rst  	  : in std_logic;                      --Positive reset
	i_data 	  : in std_logic_vector(7 down to 0);  --Input data from RAM

	o_address : out std_logic_vector(15 down to 0); --Output address of RAM
	o_en      : out std_logic;                      --Enable signal, 1 = comunicating with RAM, 0 = not comunicating
	o_we      : out std_logic;                      --Enable write signal, 1 = writing to RAM, 0 = reading from RAM 
  ) ;
end entity ; -- read_address_test

architecture test of read_address_test is

	type t_ra_state is (READADDRESSBEGIN, READADDRESSDONE, READWZBEGIN, READWZDONE, WAITFORSUCCESS, DONESUCCESS, DONEFALIURE, DONEEND) --FSM declaration for this component

	signal ra_state  : t_ra_state := READADDRESSBEGIN;          --Current state in the FSM
	signal addr      : std_logic_vector(7 down to 0) := x"00";  --The address to check
	signal currentWZ : std_logic_vector(7 down to 0) := x"00";  --The current working zone we are checking
	signal tries     : integer := 0;                            --Number of failed attempts

	signal s_done	 : std_logic := '0'; --1 = the success component is done calculating
	signal s_found	 : std_logic := '0'; --1 = the success component found the wz, 0 = the success component failed to find the wz

	signal c_start	 : std_logic := '0'; --1 = the calculation component can start
	signal c_success : std_logic := '0'; --1 = the calculation component will use the wz formula, 0 = the calculation component will use no formula

	constant ADDBASE : std_logic_vector(15 down to 0) := x"0000"; --RAM address of the first wz
	constant OFFS    : unsigned(15 down to 0) := x"0008";         --RAM offset between two wz
	constant ADDOFF  : integer := 8; 							  --Offset steps to get to the RAM address of the address we are checking

	function calculateAddress(offset : integer) return std_logic_vector(15 down to 0) is
	begin

		return ADDBASE + OFFS * offset;

	end function; --calculateAddress

begin
	
	reset : process( i_clk )
	begin
		
		if i_rst = '1' then
			if rising_edge(i_clk) then
				ra_state  <= READADDRESSBEGIN;
				addr      <= x"00";
				currentWZ <= x"00";
				tries     <= 0;
			end if ;
		end if;

	end process ; -- reset

	ask_address : process( i_clk )
	begin

		if ra_state = READADDRESSBEGIN then
			if rising_edge(i_clk) then
				o_en      <= '1';
				o_address <= calculateAddress(ADDOFF);
				ra_state  <= READADDRESSDONE;
			end if;
		end if ;

	end process ; -- ask_address

	read_address : process( i_clk )
	begin
		
		if ra_state = READADDRESSDONE then
			if rising_edge(i_clk) then
				o_en     <= '0';
				addr     <= i_data;
				ra_state <= READWZBEGIN;
			end if;
		end if ;

	end process ; -- read_address

	ask_wz : process( i_clk )
	begin

		if ra_state = READWZBEGIN then
			if rising_edge(i_clk) then
				if tries = 8 then
					ra_state <= DONEFALIURE;
				else
					o_en      <= '1';
					o_address <= calculateAddress(tries);
					ra_state  <= READWZDONE;
				end if;
			end if;
		end if ;

	end process ; -- ask_wz

	read_wz : process( i_clk )
	begin
		
		if ra_state = READWZDONE then
			if rising_edge(i_clk) then
				o_en      <= '0';
				currentWZ <= i_data;
				ra_state  <= WAITFORSUCCESS;
			end if;
		end if ;

	end process ; -- read_wz

	isSuccess : process( i_clk )
	begin
		
		if ra_state = WAITFORSUCCESS then
			if rising_edge(i_clk) then
				if s_done = '1' then
					if s_found = '0' then
						tries    <= tries + 1;
						ra_state <= READWZBEGIN;
					else
						ra_state <= DONESUCCESS;
					end if;
				end if;
			end if;
		end if ;

	end process ; -- isSuccess

	done_success : process( i_clk )
	begin
		if ra_state = DONESUCCESS then
			if rising_edge(i_clk) then
				c_success <= '1';
				c_start   <= '1';
				ra_state  <= DONEEND;
			end if;
		end if ;
	end process ; -- done_success

	done_faliure : process( i_clk )
	begin
		if ra_state = DONEFALIURE then
			if rising_edge(i_clk) then
				c_success <= '0';
				c_start   <= '1';
				ra_state  <= DONEEND;
			end if;
		end if ;
	end process ; -- done_faliure

end architecture ; -- arch