library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.gain_calculate_pkg.all;

entity mixer_datapath is
generic (num_state: natural := 18);
port(
	data_in: in signed(DATA_WIDTH_IN-1 downto 0);

	gain_ctrA0: in unsigned(GAIN_WIDTH_IN-1 downto 0);
	gain_ctrA1: in unsigned(GAIN_WIDTH_IN-1 downto 0);
	gain_ctrA2: in unsigned(GAIN_WIDTH_IN-1 downto 0);
	gain_ctrA3: in unsigned(GAIN_WIDTH_IN-1 downto 0);

	gain_ctrB0: in unsigned(GAIN_WIDTH_IN-1 downto 0);
	gain_ctrB1: in unsigned(GAIN_WIDTH_IN-1 downto 0);
	gain_ctrB2: in unsigned(GAIN_WIDTH_IN-1 downto 0);
	gain_ctrB3: in unsigned(GAIN_WIDTH_IN-1 downto 0);

	gain_ctrMA: in unsigned(GAIN_WIDTH_IN-1 downto 0);
	gain_ctrMB: in unsigned(GAIN_WIDTH_IN-1 downto 0);
	
	data_out: out signed(DATA_WIDTH_OUT-1 downto 0);

	over_flow_out: out signed(1 downto 0);
	clk: in std_logic
);
end entity;

architecture rtl of mixer_datapath is

--assign clock on FPGA board, this is generated in Lattice: Tools -> IPExpress -> PLL
--component my_pll is 
--	port(
--        CLK: in std_logic; 
--        CLKOP: out std_logic; 
--        CLKOK: out std_logic; 
--        LOCK: out std_logic
--	);
--end component;

signal curr_state: natural range 0 to 17;
signal next_state: natural range 0 to 17;

--8 registers to store temporary result of multiplication with gain level from channels
type prod8_arr is array (7 downto 0) of signed(DATA_WIDTH_IN-1 downto 0);
--initialize value 0 for registers
signal prod_buff: prod8_arr := (others => to_signed(16#0000#, DATA_WIDTH_IN));

signal sum_prod: signed(DATA_WIDTH_IN+1 downto 0);

--write to registers, 4 for Channel A: 0 to 3, 4 for Channel B: 4 to 7
signal write_add: natural range 0 to 7;
signal base_add: natural range 0 to 7;
signal base_add_A: natural;
signal base_add_B: natural;

signal gain_lvl: unsigned(GAIN_WIDTH_IN-1 downto 0);

--signal data_in: signed(DATA_WIDTH_IN-1 downto 0);

signal operation: natural range 0 to 3;

--Result of multiplication
signal prod: signed(DATA_WIDTH_IN+GAIN_WIDTH_IN downto 0);
signal last_prod: signed(DATA_WIDTH_IN+GAIN_WIDTH_IN downto 0);
--Result of addition
signal temp: signed(DATA_WIDTH_IN-1 downto 0);


constant IDLE_STATE: natural := 1;

--states for calculation on ch0
constant S00_STATE_A: natural := 2;
constant S00_STATE_B: natural := 3;
constant S01_STATE_A: natural := 4;
constant S02_STATE_A: natural := 5;

--states for calculation on ch1
constant S10_STATE_A: natural := 6;
constant S10_STATE_B: natural := 7;
constant S11_STATE_B: natural := 8;
constant S12_STATE_B: natural := 9;

--states for calculation on ch2
constant S20_STATE_A: natural := 10;
constant S20_STATE_B: natural := 11;
constant S21_STATE_A: natural := 12;
constant S22_STATE_A: natural := 13;

--states for calculation on ch3
constant S30_STATE_A: natural := 14;
constant S30_STATE_B: natural := 15;
constant S31_STATE_B: natural := 16;
constant S32_STATE_B: natural := 17;

-- Define operation
constant ADD: natural := 1;		--For adding products
constant MUL: natural := 2;		--For multiplying input signal with gain level
constant LAST_MUL: natural := 3;	--For multiplying the result of addtion with master gain

----Generate 192KHz calculation clock from 96MHz input clock
constant PERIOD: natural := 500;
constant HALF_PERIOD: natural := PERIOD/2;
signal clkCal : std_logic := '0';
signal cntVal : natural range 0 to PERIOD;

begin

--mapping clk with clock on FPGA board
--my_pll_inst: my_pll
--	port map(
--	    CLK => clk,
--        CLKOP => open,
--		CLKOK =>open,
--        LOCK => open
--	);

--change state
assign_state: process(clkCal)
begin
	if rising_edge(clkCal) then
		curr_state <= next_state;
	end if;
end process;

--Generate 192KHz calculation clock from 96MHz input clock
clk_divider: process(clk)
begin
	if rising_edge(clk) then
		if(cntVal = PERIOD-1) then
			cntVal <= 0;
			clkCal <= '0';
		else cntVal <= cntVal+1;
			if(cntVal = HALF_PERIOD-1) then clkCal <= '1'; end if;
		end if;
	
	end if;
end process;

-- State machine to copy data to registers and do calculation 
process_ch0: process(curr_state)
begin
base_add_A <= 0;
base_add_B <= 4;

case curr_state is 
	when IDLE_STATE =>
		--next_state <= S0_STATE;

	--Input: ch0, output: mixed ch_A
	when S00_STATE_A =>
		gain_lvl <= gain_ctrA0;
		operation <= MUL;		--ch0*gain_A0
		write_add <= base_add_A;	--store result to register prod_buff(0)
		next_state <= S00_STATE_B;
	when S00_STATE_B =>
		gain_lvl <= gain_ctrB0;
		operation <= MUL;		--ch0*gain_B0
		write_add <= base_add_B;	--store result to register prod_buff(4)
		next_state <= S01_STATE_A;
	when S01_STATE_A =>
		operation <= ADD;		--add products: sum_prod = prod_buff(0)+prod_buff(1)+prod_buff(2)+prod_buff(3)
		base_add <= base_add_A;
		next_state <= S02_STATE_A;
	when S02_STATE_A =>
		gain_lvl <= gain_ctrMA;
		operation <= LAST_MUL;		--sum_prod*gain_MA
		next_state <= S10_STATE_A;

	--Input: ch1, output: mixed ch_B
	when S10_STATE_A =>
		gain_lvl <= gain_ctrA1;
		operation <= MUL;		--ch0*gain_A0
		write_add <= base_add_A+1;	--store result to register prod_buff(1)
		next_state <= S10_STATE_B;
	when S10_STATE_B =>
		gain_lvl <= gain_ctrB1;
		operation <= MUL;		--ch0*gain_B0
		write_add <= base_add_B+1;	--store result to register prod_buff(5)
		next_state <= S11_STATE_B;
	when S11_STATE_B =>
		operation <= ADD;		--add products: sum_prod = prod_buff(4)+prod_buff(5)+prod_buff(6)+prod_buff(7)
		base_add <= base_add_B;
		next_state <= S12_STATE_B;
	when S12_STATE_B =>
		gain_lvl <= gain_ctrMB;
		operation <= LAST_MUL;		--sum_prod*gain_MB
		next_state <= S20_STATE_A;

	--Input: ch2, output: mixed ch_A
	when S20_STATE_A =>
		gain_lvl <= gain_ctrA2;
		operation <= MUL;		--ch2*gain_A2
		write_add <= base_add_A+2;	--store result to register prod_buff(2)
		next_state <= S20_STATE_B;
	when S20_STATE_B =>
		gain_lvl <= gain_ctrB2;
		operation <= MUL;		--ch2*gain_B2
		write_add <= base_add_B+2;	--store result to register prod_buff(6)
		next_state <= S21_STATE_A;
	when S21_STATE_A =>
		operation <= ADD;		--add products: sum_prod = prod_buff(0)+prod_buff(1)+prod_buff(2)+prod_buff(3)
		base_add <= base_add_A;
		next_state <= S22_STATE_A;
	when S22_STATE_A =>
		gain_lvl <= gain_ctrMA;
		operation <= LAST_MUL;		--sum_prod*gain_MA
		next_state <= S30_STATE_A;

	--Input: ch3, output: mixed ch_B
	when S30_STATE_A =>
		gain_lvl <= gain_ctrA3;
		operation <= MUL;		--ch3*gain_A3
		write_add <= base_add_A+3;	--store result to register prod_buff(3)
		next_state <= S30_STATE_B;
	when S30_STATE_B =>
		gain_lvl <= gain_ctrB3;
		operation <= MUL;		--ch3*gain_B3
		write_add <= base_add_B+3;	--store result to register prod_buff(7)
		next_state <= S31_STATE_B;
	when S31_STATE_B =>
		operation <= ADD;		--add products: sum_prod = prod_buff(4)+prod_buff(5)+prod_buff(6)+prod_buff(7)
		base_add <= base_add_B;
		next_state <= S32_STATE_B;
	when S32_STATE_B =>
		gain_lvl <= gain_ctrMB;
		operation <= LAST_MUL;		--sum_prod*gain_MB
		next_state <= S00_STATE_A;

	when others =>
		next_state <= S00_STATE_A;
end case;
	
end process;

-- Calculate the result
calculate: process(operation, data_in, gain_lvl, temp, base_add)
begin
case operation is
	when MUL =>
		prod <= gainCal(data_in, gain_lvl);
	when ADD =>
		sum_prod <= overFlowCal(prod_buff(base_add), prod_buff(base_add+1), prod_buff(base_add+2), prod_buff(base_add+3));
	when LAST_MUL =>
		last_prod <= gainCal(temp, gain_lvl);
	when others =>
end case;
end process;

--get overflow flag and addition result
analyze_sum: process(sum_prod)
begin
	over_flow_out <= sum_prod(DATA_WIDTH_IN+1 downto DATA_WIDTH_IN);
	temp <= sum_prod(DATA_WIDTH_IN-1 downto 0);
end process;

--limit the result of multiplication to 16 bits and store to register
write_to_buff: process(prod, write_add)
begin
	prod_buff(write_add) <= limitResult(prod);
end process;

--limit the result of mulitplication to 24 bits and output result
output_result: process(last_prod)
begin
	data_out <= limitFinalResult(last_prod);

end process;

end architecture;