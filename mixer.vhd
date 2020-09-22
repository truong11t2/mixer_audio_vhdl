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

component my_pll is 
	port(
        CLK: in std_logic; 
        CLKOP: out std_logic; 
        CLKOK: out std_logic; 
        LOCK: out std_logic
	);
end component;

signal curr_state: natural range 0 to 17;
signal next_state: natural range 0 to 17;

--8 registers to store temporary result of multiplication with gain level from chanels
type prod8_arr is array (7 downto 0) of signed(DATA_WIDTH_IN-1 downto 0);
signal prod_buff: prod8_arr := (others => to_signed(16#0000#, DATA_WIDTH_IN));

signal sum_prod: signed(DATA_WIDTH_IN+1 downto 0);

-- Eight registers to store data stream, 4 for Channel A, 4 for Channel B
signal write_add: natural range 0 to 7;
signal base_add: natural range 0 to 7;
signal base_add_A: natural := 0;
signal base_add_B: natural := 4;

signal gain_lvl: unsigned(GAIN_WIDTH_IN-1 downto 0);

--signal data_in: signed(DATA_WIDTH_IN-1 downto 0);

signal operation: natural range 0 to 3;

--Result of multiplication
signal prod: signed(DATA_WIDTH_IN+GAIN_WIDTH_IN downto 0);
signal last_prod: signed(DATA_WIDTH_IN+GAIN_WIDTH_IN downto 0);
signal temp: signed(DATA_WIDTH_IN-1 downto 0);


constant IDLE_STATE: natural := 1;

constant S00_STATE_A: natural := 2;
constant S00_STATE_B: natural := 3;
constant S01_STATE_A: natural := 4;
constant S02_STATE_A: natural := 5;

constant S10_STATE_A: natural := 6;
constant S10_STATE_B: natural := 7;
constant S11_STATE_B: natural := 8;
constant S12_STATE_B: natural := 9;

constant S20_STATE_A: natural := 10;
constant S20_STATE_B: natural := 11;
constant S21_STATE_A: natural := 12;
constant S22_STATE_A: natural := 13;

constant S30_STATE_A: natural := 14;
constant S30_STATE_B: natural := 15;
constant S31_STATE_B: natural := 16;
constant S32_STATE_B: natural := 17;

-- Define operation
constant ADD: natural := 1;
constant MUL: natural := 2;
constant LAST_MUL: natural := 3;

signal start_cal: natural range 0 to 3;
constant CH_0: natural := 0;
constant CH_1: natural := 1;
constant CH_2: natural := 2;
constant CH_3: natural := 3;
constant FOR_CH_0: natural := 0;
constant FOR_CH_1: natural := 1;
constant FOR_CH_2: natural := 2;
constant FOR_CH_3: natural := 3;

constant PERIOD: natural := 500;
constant HALF_PERIOD: natural := PERIOD/2;
signal clkCal : std_logic := '0';
signal cntVal : natural range 0 to PERIOD;

begin

--my_pll_inst: my_pll
--	port map(
--	    CLK => clk,
--        CLKOP => open,
--		CLKOK =>open,
--        LOCK => open
--	);
assign_state: process(clkCal)
begin
	if rising_edge(clkCal) then
		curr_state <= next_state;
	end if;
end process;

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
process_ch0: process(curr_state, start_cal)
begin

--if(start_cal = 1) then --start calculation for channel 0
case curr_state is 
	when IDLE_STATE =>
		--next_state <= S0_STATE;
	when S00_STATE_A =>
		gain_lvl <= gain_ctrA0;
		operation <= MUL;
		write_add <= base_add_A;
		next_state <= S00_STATE_B;
	when S00_STATE_B =>
		gain_lvl <= gain_ctrB0;
		operation <= MUL;
		write_add <= base_add_B;
		next_state <= S01_STATE_A;
	when S01_STATE_A =>
		operation <= ADD;
		base_add <= base_add_A;
		next_state <= S02_STATE_A;
	when S02_STATE_A =>
		gain_lvl <= gain_ctrMA;
		operation <= LAST_MUL;
		next_state <= S10_STATE_A;

	when S10_STATE_A =>
		gain_lvl <= gain_ctrA1;
		operation <= MUL;
		write_add <= base_add_A+1;
		next_state <= S10_STATE_B;
	when S10_STATE_B =>
		gain_lvl <= gain_ctrB1;
		operation <= MUL;
		write_add <= base_add_B+1;
		next_state <= S11_STATE_B;
	when S11_STATE_B =>
		operation <= ADD;
		base_add <= base_add_B;
		next_state <= S12_STATE_B;
	when S12_STATE_B =>
		gain_lvl <= gain_ctrMB;
		operation <= LAST_MUL;
		next_state <= S20_STATE_A;

	when S20_STATE_A =>
		gain_lvl <= gain_ctrA2;
		operation <= MUL;
		write_add <= base_add_A+2;
		next_state <= S20_STATE_B;
	when S20_STATE_B =>
		gain_lvl <= gain_ctrB2;
		operation <= MUL;
		write_add <= base_add_B+2;
		next_state <= S21_STATE_A;
	when S21_STATE_A =>
		operation <= ADD;
		base_add <= base_add_A;
		next_state <= S22_STATE_A;
	when S22_STATE_A =>
		gain_lvl <= gain_ctrMA;
		operation <= LAST_MUL;
		next_state <= S30_STATE_A;

	when S30_STATE_A =>
		gain_lvl <= gain_ctrA3;
		operation <= MUL;
		write_add <= base_add_A+3;
		next_state <= S30_STATE_B;
	when S30_STATE_B =>
		gain_lvl <= gain_ctrB3;
		operation <= MUL;
		write_add <= base_add_B+3;
		next_state <= S31_STATE_B;
	when S31_STATE_B =>
		operation <= ADD;
		base_add <= base_add_B;
		next_state <= S32_STATE_B;
	when S32_STATE_B =>
		gain_lvl <= gain_ctrMB;
		operation <= LAST_MUL;
		next_state <= S00_STATE_A;

	when others =>
		next_state <= S00_STATE_A;
end case;
--end if; --end calculation
	
end process;

-- Calculate the result
calculate: process(operation, data_in, gain_lvl, write_add)
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

analyze_sum: process(sum_prod)
begin
	over_flow_out <= sum_prod(DATA_WIDTH_IN+1 downto DATA_WIDTH_IN);
	temp <= sum_prod(DATA_WIDTH_IN-1 downto 0);
end process;

write_to_buff: process(prod, write_add)
begin
	prod_buff(write_add) <= limitResult(prod);
end process;

output_result: process(last_prod)
begin
	data_out <= limitFinalResult(last_prod);

end process;

end architecture;