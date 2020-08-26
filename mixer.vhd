library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.gain_calculate_pkg.all;

entity mixer_datapath is
generic (num_state: natural := 7);
port(
	ch0_in: in signed(DATA_WIDTH_IN-1 downto 0);
	ch1_in: in signed(DATA_WIDTH_IN-1 downto 0);
	ch2_in: in signed(DATA_WIDTH_IN-1 downto 0);
	ch3_in: in signed(DATA_WIDTH_IN-1 downto 0);

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

	mix_chA_out: out signed(DATA_WIDTH_OUT-1 downto 0);
	mix_chB_out: out signed(DATA_WIDTH_OUT-1 downto 0);
	over_flow_A: out signed(1 downto 0);
	over_flow_B: out signed(1 downto 0);
	clk: in std_logic
);
end entity;

architecture rtl of mixer_datapath is

signal curr_state: natural range 0 to num_state - 1;
signal next_state: natural range 0 to num_state - 1;

--8 registers to store temporary result of multiplication with gain level from chanels
type prod8_arr is array (9 downto 0) of signed(DATA_WIDTH_IN+GAIN_WIDTH_IN downto 0);
signal prod_buff: prod8_arr;

signal sum_prod_A: signed(DATA_WIDTH_IN+1 downto 0);
signal sum_prod_B: signed(DATA_WIDTH_IN+1 downto 0);

-- Eight registers to store data stream, 4 for Channel A, 4 for Channel B
signal write_add_A: natural range 0 to 9;
signal write_add_B: natural range 0 to 9;

signal read_ch: natural range 0 to 4;
signal gain_lvl_A: unsigned(GAIN_WIDTH_IN-1 downto 0);
signal gain_lvl_B: unsigned(GAIN_WIDTH_IN-1 downto 0);

signal data_in: signed(DATA_WIDTH_IN-1 downto 0);

signal operation: natural range 0 to 3;

--Result of multiplication
signal prod_A: signed(DATA_WIDTH_IN+GAIN_WIDTH_IN downto 0);
signal prod_B: signed(DATA_WIDTH_IN+GAIN_WIDTH_IN downto 0);
signal temp_A: signed(DATA_WIDTH_IN-1 downto 0);
signal temp_B: signed(DATA_WIDTH_IN-1 downto 0);


signal reg_in_sel: natural range 0 to 3;

constant FROM_CH0: natural := 0;
constant FROM_CH1: natural := 1;
constant FROM_CH2: natural := 2;
constant FROM_CH3: natural := 3;
constant FROM_SUM_A: natural := 4;
constant FROM_SUM_B: natural := 5;

constant IDLE_STATE: natural := 0;
constant S0_STATE: natural := 1;
constant S1_STATE: natural := 2;
constant S2_STATE: natural := 3;
constant S3_STATE: natural := 4;
constant S4_STATE: natural := 5;
constant S5_STATE: natural := 6;

-- Define operation
constant ADD: natural := 1;
constant MUL: natural := 2;
constant LAST_MUL: natural := 3;

begin

--Update state
assign_state: process(clk)
begin
	if rising_edge(clk) then
		curr_state <= next_state;
	end if;
end process;
-- State machine to copy data to registers and do calculation 
process_ch0: process(curr_state, gain_ctrA0, gain_ctrA1, gain_ctrA2, gain_ctrA3, gain_ctrB0, gain_ctrB1, gain_ctrB2, gain_ctrB3)
begin
	write_add_A <= 0;
	write_add_B <= 4;
	next_state <= curr_state;
	case curr_state is 
		when IDLE_STATE =>
			next_state <= S0_STATE;
		when S0_STATE =>
			reg_in_sel <= FROM_CH0;
			gain_lvl_A <= gain_ctrA0;
			gain_lvl_B <= gain_ctrB0;
			operation <= MUL;
			write_add_A <= 0;
			write_add_B <= 4;
			next_state <= S1_STATE;
		when S1_STATE =>
			reg_in_sel <= FROM_CH1;
			gain_lvl_A <= gain_ctrA1;
			gain_lvl_B <= gain_ctrB1;
			operation <= MUL;
			write_add_A <= 1;
			write_add_B <= 5;
			next_state <= S2_STATE;
		when S2_STATE =>
			reg_in_sel <= FROM_CH2;
			gain_lvl_A <= gain_ctrA2;
			gain_lvl_B <= gain_ctrB2;
			operation <= MUL;
			write_add_A <= 2;
			write_add_B <= 6;
			next_state <= S3_STATE;
		when S3_STATE =>
			reg_in_sel <= FROM_CH3;
			gain_lvl_A <= gain_ctrA3;
			gain_lvl_B <= gain_ctrB3;
			operation <= MUL;
			write_add_A <= 3;
			write_add_B <= 7;
			next_state <= S4_STATE;
		when S4_STATE =>
			operation <= ADD;
			next_state <= S5_STATE;
		when S5_STATE =>
			gain_lvl_A <= gain_ctrMA;
			gain_lvl_B <= gain_ctrMB;
			operation <= LAST_MUL;
			write_add_A <= 8;
			write_add_B <= 9;
			next_state <= S0_STATE;
		when others =>
			next_state <= IDLE_STATE;
	end case;
	
end process;


--write_to_reg: process(write_add_A, write_add_B)
--begin
--	prod_buff(write_add_A) <= signed(prod_A);
--	prod_buff(write_add_B) <= signed(prod_B);
--end process;

reg_in_muxA: process(reg_in_sel, ch0_in, ch1_in, ch2_in, ch3_in)
begin
	case reg_in_sel is
	when FROM_CH0 => data_in <= ch0_in;
	when FROM_CH1 => data_in <= ch1_in;
	when FROM_CH2 => data_in <= ch2_in;
	when FROM_CH3 => data_in <= ch3_in;
	when others => data_in <= (others => '0');
	end case;
end process;

-- Calculate the result
calculate: process(operation, data_in, gain_lvl_A, gain_lvl_B)

begin
	case operation is
		when MUL =>
			prod_A <= gainCal(data_in, gain_lvl_A);
			prod_B <= gainCal(data_in, gain_lvl_B);
		when ADD =>
			sum_prod_A <= overFlowCal(prod_buff(0), prod_buff(1), prod_buff(2), prod_buff(3));
			over_flow_A <= sum_prod_A(DATA_WIDTH_IN+1 downto DATA_WIDTH_IN);
			temp_A <= sum_prod_A(DATA_WIDTH_IN-1 downto 0);
			sum_prod_B <= overFlowCal(prod_buff(4), prod_buff(5), prod_buff(6), prod_buff(7));
			over_flow_B <= sum_prod_B(DATA_WIDTH_IN+1 downto DATA_WIDTH_IN);
			temp_B <= sum_prod_B(DATA_WIDTH_IN-1 downto 0);
		when LAST_MUL =>
			prod_A <= gainCal(temp_A, gain_lvl_A);
			mix_chA_out <= prod_A(DATA_WIDTH_IN+GAIN_WIDTH_IN downto (DATA_WIDTH_IN+GAIN_WIDTH_IN-DATA_WIDTH_OUT)+1);
			prod_B <= gainCal(temp_B, gain_lvl_B);
			mix_chB_out <= prod_B(DATA_WIDTH_IN+GAIN_WIDTH_IN downto (DATA_WIDTH_IN+GAIN_WIDTH_IN-DATA_WIDTH_OUT)+1);
		when others =>
	end case;
end process;

write_to_buff: process(prod_A, prod_B)
begin
--if rising_edge(clk) then
	prod_buff(write_add_A) <= prod_A;
	prod_buff(write_add_B) <= prod_B;
--end if;
end process;
end architecture;