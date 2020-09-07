library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.gain_calculate_pkg.all;

entity mixer_datapath is
generic (num_state: natural := 4);
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

	over_flow_chA_out: out signed(1 downto 0);
	over_flow_chB_out: out signed(1 downto 0);
	clk: in std_logic
);
end entity;

architecture rtl of mixer_datapath is

signal curr_cal: natural range 0 to 3;
signal next_cal: natural range 0 to 3;
signal curr_state: natural range 0 to 2**num_state;
signal next_state: natural range 0 to 2**num_state;

--8 registers to store temporary result of multiplication with gain level from chanels
type prod8_arr is array (7 downto 0) of signed(DATA_WIDTH_IN-1 downto 0);
signal prod_buff: prod8_arr := (others => to_signed(16#0000#, DATA_WIDTH_IN));

type gain10_arr is array (9 downto 0) of unsigned(GAIN_WIDTH_IN-1 downto 0);
signal gain_buff: gain10_arr;

signal sum_prod_A: signed(DATA_WIDTH_IN+1 downto 0);
signal sum_prod_B: signed(DATA_WIDTH_IN+1 downto 0);

-- Eight registers to store data stream, 4 for Channel A, 4 for Channel B
signal write_add_A: natural range 0 to 9;
signal write_add_B: natural range 0 to 9;

signal gain_lvl_A: unsigned(GAIN_WIDTH_IN-1 downto 0);
signal gain_lvl_B: unsigned(GAIN_WIDTH_IN-1 downto 0);

--signal data_in: signed(DATA_WIDTH_IN-1 downto 0);

signal operation: natural range 0 to 3;

--Result of multiplication
signal prod_A: signed(DATA_WIDTH_IN+GAIN_WIDTH_IN downto 0);
signal prod_B: signed(DATA_WIDTH_IN+GAIN_WIDTH_IN downto 0);
signal last_prod_A: signed(DATA_WIDTH_IN+GAIN_WIDTH_IN downto 0);
signal last_prod_B: signed(DATA_WIDTH_IN+GAIN_WIDTH_IN downto 0);
signal temp_A: signed(DATA_WIDTH_IN-1 downto 0);
signal temp_B: signed(DATA_WIDTH_IN-1 downto 0);

signal reg_in_sel: natural range 0 to 6;

constant FROM_CH0: natural := 1;
constant FROM_CH1: natural := 2;
constant FROM_CH2: natural := 3;
constant FROM_CH3: natural := 4;
constant FROM_SUM_A: natural := 5;
constant FROM_SUM_B: natural := 6;

constant IDLE_STATE: natural := 2;
constant S0_STATE: natural := 4;
constant S1_STATE: natural := 8;
constant S2_STATE: natural := 16;
constant S3_STATE: natural := 32;
constant S4_STATE: natural := 64;
constant S5_STATE: natural := 128;

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

signal out_A: boolean := true;
signal	mix_chA_out: signed(DATA_WIDTH_OUT-1 downto 0);
signal	mix_chB_out: signed(DATA_WIDTH_OUT-1 downto 0);


begin

assign_cal: process(data_in)

begin
	curr_cal <= next_cal;
	if(out_A = true) then data_out <= mix_chA_out; out_A <= false;
	else data_out <= mix_chB_out; out_A <= true;
	end if;
end process;

process_cal: process(curr_cal, clk)
begin
if rising_edge(clk) then
case curr_cal is
when CH_0 =>
	start_cal <= FOR_CH_0;
	next_cal <= CH_1;
when CH_1 =>
	start_cal <= FOR_CH_1;
	next_cal <= CH_2;
when CH_2 =>
	start_cal <= FOR_CH_2;
	next_cal <= CH_3;
when CH_3 =>
	start_cal <= FOR_CH_3;
	next_cal <= CH_0;
when others =>

end case;
end if;
end process;

--Update state
assign_state: process(clk)
begin
	if rising_edge(clk) then
		curr_state <= next_state;
	end if;
end process;

-- State machine to copy data to registers and do calculation 
process_ch0: process(curr_state)
begin

if(start_cal = FOR_CH_0) then --start calculation for channel 0
	case curr_state is 
		when IDLE_STATE =>
			--next_state <= S0_STATE;
		when S0_STATE =>
			gain_lvl_A <= gain_ctrA0;
			gain_lvl_B <= gain_ctrB0;
			operation <= MUL;
			write_add_A <= 0;
			write_add_B <= 4;
			next_state <= S1_STATE;
		when S1_STATE =>
			operation <= ADD;
			next_state <= S2_STATE;
		when S2_STATE =>
			gain_lvl_A <= gain_ctrMA;
			gain_lvl_B <= gain_ctrMB;
			operation <= LAST_MUL;
			next_state <= S0_STATE;
		when others =>
			next_state <= S0_STATE;
	end case;
elsif (start_cal = FOR_CH_1) then --start calculation for channel 1
	case curr_state is 
		when IDLE_STATE =>
			next_state <= S0_STATE;
		when S0_STATE =>
			gain_lvl_A <= gain_ctrA1;
			gain_lvl_B <= gain_ctrB1;
			operation <= MUL;
			write_add_A <= 1;
			write_add_B <= 5;
			next_state <= S1_STATE;
		when S1_STATE =>
			operation <= ADD;
			next_state <= S2_STATE;
		when S2_STATE =>
			gain_lvl_A <= gain_ctrMA;
			gain_lvl_B <= gain_ctrMB;
			operation <= LAST_MUL;
			next_state <= S0_STATE;
		when others =>
			next_state <= S0_STATE;
	end case;
elsif (start_cal = FOR_CH_2) then --start calculation for channel 2
	case curr_state is 
		when IDLE_STATE =>
			next_state <= S0_STATE;
		when S0_STATE =>
			gain_lvl_A <= gain_ctrA2;
			gain_lvl_B <= gain_ctrB2;
			operation <= MUL;
			write_add_A <= 2;
			write_add_B <= 6;
			next_state <= S1_STATE;
		when S1_STATE =>
			operation <= ADD;
			next_state <= S2_STATE;
		when S2_STATE =>
			gain_lvl_A <= gain_ctrMA;
			gain_lvl_B <= gain_ctrMB;
			operation <= LAST_MUL;
			next_state <= S0_STATE;
		when others =>
			next_state <= S0_STATE;
	end case;
elsif (start_cal = FOR_CH_3) then --start calculation for channel 3
	case curr_state is 
		when IDLE_STATE =>
			next_state <= S0_STATE;
		when S0_STATE =>
			gain_lvl_A <= gain_ctrA3;
			gain_lvl_B <= gain_ctrB3;
			operation <= MUL;
			write_add_A <= 3;
			write_add_B <= 7;
			next_state <= S1_STATE;
		when S1_STATE =>
			operation <= ADD;
			next_state <= S2_STATE;
		when S2_STATE =>
			gain_lvl_A <= gain_ctrMA;
			gain_lvl_B <= gain_ctrMB;
			operation <= LAST_MUL;
			next_state <= S0_STATE;
		when others =>
			next_state <= S0_STATE;
	end case;
end if; --end calculation
	
end process;

-- Calculate the result
calculate: process(operation, data_in, gain_lvl_A, gain_lvl_B, curr_state)
--calculate: process(clk)
begin
--if rising_edge(clk) then
	case operation is
		when MUL =>
			prod_A <= gainCal(data_in, gain_lvl_A);
			prod_B <= gainCal(data_in, gain_lvl_B);
		when ADD =>
			sum_prod_A <= overFlowCal(prod_buff(0), prod_buff(1), prod_buff(2), prod_buff(3));
			sum_prod_B <= overFlowCal(prod_buff(4), prod_buff(5), prod_buff(6), prod_buff(7));
		when LAST_MUL =>
			last_prod_A <= gainCal(temp_A, gain_lvl_B);
			last_prod_B <= gainCal(temp_B, gain_lvl_B);
		when others =>
	end case;
--end if;
end process;

analyze_sum: process(sum_prod_A, sum_prod_B)
begin
	over_flow_chA_out <= sum_prod_A(DATA_WIDTH_IN+1 downto DATA_WIDTH_IN);
	temp_A <= sum_prod_A(DATA_WIDTH_IN-1 downto 0);
	over_flow_chB_out <= sum_prod_B(DATA_WIDTH_IN+1 downto DATA_WIDTH_IN);
	temp_B <= sum_prod_B(DATA_WIDTH_IN-1 downto 0);
end process;

write_to_buff: process(prod_A, prod_B, write_add_A, write_add_B)
begin
	prod_buff(write_add_A) <= limitResult(prod_A);
	prod_buff(write_add_B) <= limitResult(prod_B);
end process;

output_result: process(last_prod_A, last_prod_B)
begin
	mix_chA_out <= limitFinalResult(last_prod_A);
	mix_chB_out <= limitFinalResult(last_prod_B);
end process;
end architecture;