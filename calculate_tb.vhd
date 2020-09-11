library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.gain_calculate_pkg.all;

entity calculate_tb is
end entity;

architecture stimuli of calculate_tb is
component calculate is
port(
	ch0: in signed(DATA_WIDTH_IN-1 downto 0);
	ch1: in signed(DATA_WIDTH_IN-1 downto 0);
	ch2: in signed(DATA_WIDTH_IN-1 downto 0);
	ch3: in signed(DATA_WIDTH_IN-1 downto 0);

	a0: in unsigned(GAIN_WIDTH_IN-1 downto 0);
	clk: in std_logic;

	mul_a0: out signed(DATA_WIDTH_IN+GAIN_WIDTH_IN downto 0);
	lim_16bit_mul_a0: out signed(DATA_WIDTH_IN-1 downto 0);
	lim_24bit_mul_a0: out signed(DATA_WIDTH_OUT-1 downto 0);
	add_rsl: out signed(DATA_WIDTH_IN-1 downto 0);
	over_flow_flg: out signed(1 downto 0)
);
end component;

signal ch0_dut: signed(DATA_WIDTH_IN-1 downto 0);
signal ch1_dut: signed(DATA_WIDTH_IN-1 downto 0);
signal ch2_dut: signed(DATA_WIDTH_IN-1 downto 0);
signal ch3_dut: signed(DATA_WIDTH_IN-1 downto 0);

signal a0_dut: unsigned(GAIN_WIDTH_IN-1 downto 0);

signal mul_a0_dut: signed(DATA_WIDTH_IN+GAIN_WIDTH_IN downto 0);
signal lim_16bit_mul_a0_dut: signed(DATA_WIDTH_IN-1 downto 0);
signal lim_24bit_mul_a0_dut: signed(DATA_WIDTH_OUT-1 downto 0);
signal add_rsl_dut: signed(DATA_WIDTH_IN-1 downto 0);
signal over_flow_flg_dut: signed(1 downto 0);

signal clk_dut: std_logic := '0';

constant clk_cyl: time := 10 ns;


begin
dut: calculate
port map (
	ch0 => ch0_dut,
	ch1 => ch1_dut,
	ch2 => ch2_dut,
	ch3 => ch3_dut,

	a0 => a0_dut,
	clk => clk_dut,

	mul_a0 => mul_a0_dut,
	lim_16bit_mul_a0 => lim_16bit_mul_a0_dut,
	lim_24bit_mul_a0 => lim_24bit_mul_a0_dut,
	add_rsl => add_rsl_dut,
	over_flow_flg => over_flow_flg_dut
);
clk_dut <= not clk_dut after clk_cyl/2;
stimuli: process
begin

-----------FOR GAI_01

--	ch0_dut <= to_signed(1, DATA_WIDTH_IN);
--	a0_dut <= to_unsigned(0, GAIN_WIDTH_IN);
--	wait for clk_cyl;
--	ch0_dut <= to_signed(1, DATA_WIDTH_IN);
--	a0_dut <= to_unsigned(32, GAIN_WIDTH_IN);
--	wait for clk_cyl;
--	ch0_dut <= to_signed(1, DATA_WIDTH_IN);
--	a0_dut <= to_unsigned(96, GAIN_WIDTH_IN);
--	wait for clk_cyl;
--	ch0_dut <= to_signed(1, DATA_WIDTH_IN);
--	a0_dut <= to_unsigned(224, GAIN_WIDTH_IN);
--	wait for clk_cyl;
--	ch0_dut <= to_signed(1, DATA_WIDTH_IN);
--	a0_dut <= to_unsigned(480, GAIN_WIDTH_IN);
--	wait for clk_cyl;
--	ch0_dut <= to_signed(1, DATA_WIDTH_IN);
--	a0_dut <= to_unsigned(992, GAIN_WIDTH_IN);
--	wait for clk_cyl;

-----------FOR LOS_01

--	ch0_dut <= to_signed(-512, DATA_WIDTH_IN);
--	a0_dut <= to_unsigned(1, GAIN_WIDTH_IN);
--	wait for clk_cyl;
--	ch0_dut <= to_signed(-768, DATA_WIDTH_IN);
--	a0_dut <= to_unsigned(3, GAIN_WIDTH_IN);
--	wait for clk_cyl;
--	ch0_dut <= to_signed(-896, DATA_WIDTH_IN);
--	a0_dut <= to_unsigned(7, GAIN_WIDTH_IN);
--	wait for clk_cyl;
--	ch0_dut <= to_signed(-960, DATA_WIDTH_IN);
--	a0_dut <= to_unsigned(15, GAIN_WIDTH_IN);
--	wait for clk_cyl;
--	ch0_dut <= to_signed(-992, DATA_WIDTH_IN);
--	a0_dut <= to_unsigned(31, GAIN_WIDTH_IN);
--	wait for clk_cyl;

-----------FOR MUL_01

--	ch0_dut <= to_signed(0, DATA_WIDTH_IN);
--	a0_dut <= to_unsigned(0, GAIN_WIDTH_IN);
--	wait for clk_cyl;
--
--	ch0_dut <= to_signed(234, DATA_WIDTH_IN);
--	a0_dut <= to_unsigned(0, GAIN_WIDTH_IN);
--	wait for clk_cyl;
--
--	ch0_dut <= to_signed(0, DATA_WIDTH_IN);
--	a0_dut <= to_unsigned(96, GAIN_WIDTH_IN);
--	wait for clk_cyl;
--
--	ch0_dut <= to_signed(153, DATA_WIDTH_IN);
--	a0_dut <= to_unsigned(32, GAIN_WIDTH_IN);
--	wait for clk_cyl;
--
--	ch0_dut <= to_signed(-61, DATA_WIDTH_IN);
--	a0_dut <= to_unsigned(512, GAIN_WIDTH_IN);
--	wait for clk_cyl;
--
--	ch0_dut <= to_signed(0, DATA_WIDTH_IN);
--	a0_dut <= to_unsigned(16, GAIN_WIDTH_IN);
--	wait for clk_cyl;
--
--	ch0_dut <= to_signed(-10, DATA_WIDTH_IN);
--	a0_dut <= to_unsigned(24, GAIN_WIDTH_IN);
--	wait for clk_cyl;
--
--	ch0_dut <= to_signed(1024, DATA_WIDTH_IN);
--	a0_dut <= to_unsigned(1, GAIN_WIDTH_IN);
--	wait for clk_cyl;
--
--	ch0_dut <= to_signed(-3784, DATA_WIDTH_IN);
--	a0_dut <= to_unsigned(31, GAIN_WIDTH_IN);
--	wait for clk_cyl;

-----------FOR MUL_02

--	ch0_dut <= to_signed(8094, DATA_WIDTH_IN);
--	a0_dut <= to_unsigned(992, GAIN_WIDTH_IN);
--	wait for clk_cyl;
--
--	ch0_dut <= to_signed(-9651, DATA_WIDTH_IN);
--	a0_dut <= to_unsigned(992, GAIN_WIDTH_IN);
--	wait for clk_cyl;
--
--	ch0_dut <= to_signed(32767, DATA_WIDTH_IN);
--	a0_dut <= to_unsigned(31, GAIN_WIDTH_IN);
--	wait for clk_cyl;
--
--	ch0_dut <= to_signed(-32768, DATA_WIDTH_IN);
--	a0_dut <= to_unsigned(31, GAIN_WIDTH_IN);
--	wait for clk_cyl;
--
--	ch0_dut <= to_signed(32767, DATA_WIDTH_IN);
--	a0_dut <= to_unsigned(992, GAIN_WIDTH_IN);
--	wait for clk_cyl;
--
--	ch0_dut <= to_signed(-32768, DATA_WIDTH_IN);
--	a0_dut <= to_unsigned(992, GAIN_WIDTH_IN);
--	wait for clk_cyl;

-----------FOR LIM_01 AND LIM_02

--	ch0_dut <= to_signed(343, DATA_WIDTH_IN);
--	a0_dut <= to_unsigned(0, GAIN_WIDTH_IN);
--	wait for clk_cyl;
--
--	ch0_dut <= to_signed(0, DATA_WIDTH_IN);
--	a0_dut <= to_unsigned(0, GAIN_WIDTH_IN);
--	wait for clk_cyl;
--
--	ch0_dut <= to_signed(8743, DATA_WIDTH_IN);
--	a0_dut <= to_unsigned(0, GAIN_WIDTH_IN);
--	wait for clk_cyl;
--
--	ch0_dut <= to_signed(32767, DATA_WIDTH_IN);
--	a0_dut <= to_unsigned(0, GAIN_WIDTH_IN);
--	wait for clk_cyl;
--
--	ch0_dut <= to_signed(-32768, DATA_WIDTH_IN);
--	a0_dut <= to_unsigned(0, GAIN_WIDTH_IN);
--	wait for clk_cyl;
--
--	ch0_dut <= to_signed(32767, DATA_WIDTH_IN);
--	a0_dut <= to_unsigned(992, GAIN_WIDTH_IN);
--	wait for clk_cyl;
--
--	ch0_dut <= to_signed(-32768, DATA_WIDTH_IN);
--	a0_dut <= to_unsigned(992, GAIN_WIDTH_IN);
--	wait for clk_cyl;

-----------FOR OVF_01 AND OVF_02

	ch0_dut <= to_signed(34, DATA_WIDTH_IN);
	ch1_dut <= to_signed(8973, DATA_WIDTH_IN);
	ch2_dut <= to_signed(3243, DATA_WIDTH_IN);
	ch3_dut <= to_signed(6876, DATA_WIDTH_IN);
	wait for clk_cyl;

	ch0_dut <= to_signed(34, DATA_WIDTH_IN);
	ch1_dut <= to_signed(8973, DATA_WIDTH_IN);
	ch2_dut <= to_signed(3243, DATA_WIDTH_IN);
	ch3_dut <= to_signed(20743, DATA_WIDTH_IN);
	wait for clk_cyl;

	ch0_dut <= to_signed(1, DATA_WIDTH_IN);
	ch1_dut <= to_signed(0, DATA_WIDTH_IN);
	ch2_dut <= to_signed(0, DATA_WIDTH_IN);
	ch3_dut <= to_signed(32767, DATA_WIDTH_IN);
	wait for clk_cyl;

	ch0_dut <= to_signed(-34, DATA_WIDTH_IN);
	ch1_dut <= to_signed(-8973, DATA_WIDTH_IN);
	ch2_dut <= to_signed(-3243, DATA_WIDTH_IN);
	ch3_dut <= to_signed(-6876, DATA_WIDTH_IN);
	wait for clk_cyl;

	ch0_dut <= to_signed(-34, DATA_WIDTH_IN);
	ch1_dut <= to_signed(-8973, DATA_WIDTH_IN);
	ch2_dut <= to_signed(-3243, DATA_WIDTH_IN);
	ch3_dut <= to_signed(-20743, DATA_WIDTH_IN);
	wait for clk_cyl;

	ch0_dut <= to_signed(-1, DATA_WIDTH_IN);
	ch1_dut <= to_signed(-1, DATA_WIDTH_IN);
	ch2_dut <= to_signed(-1, DATA_WIDTH_IN);
	ch3_dut <= to_signed(-32768, DATA_WIDTH_IN);
	wait for clk_cyl;

-----------FOR OVF_03

	ch0_dut <= to_signed(-32768, DATA_WIDTH_IN);
	ch1_dut <= to_signed(-32767, DATA_WIDTH_IN);
	ch2_dut <= to_signed(32767, DATA_WIDTH_IN);
	ch3_dut <= to_signed(32767, DATA_WIDTH_IN);
	wait for clk_cyl;

	ch0_dut <= to_signed(-34, DATA_WIDTH_IN);
	ch1_dut <= to_signed(8973, DATA_WIDTH_IN);
	ch2_dut <= to_signed(-3243, DATA_WIDTH_IN);
	ch3_dut <= to_signed(20743, DATA_WIDTH_IN);
	wait for clk_cyl;

	ch0_dut <= to_signed(-323, DATA_WIDTH_IN);
	ch1_dut <= to_signed(-1, DATA_WIDTH_IN);
	ch2_dut <= to_signed(32767, DATA_WIDTH_IN);
	ch3_dut <= to_signed(324, DATA_WIDTH_IN);
	wait for clk_cyl;

	ch0_dut <= to_signed(-323, DATA_WIDTH_IN);
	ch1_dut <= to_signed(-1, DATA_WIDTH_IN);
	ch2_dut <= to_signed(32767, DATA_WIDTH_IN);
	ch3_dut <= to_signed(325, DATA_WIDTH_IN);
	wait for clk_cyl;

	ch0_dut <= to_signed(-32333, DATA_WIDTH_IN);
	ch1_dut <= to_signed(-12321, DATA_WIDTH_IN);
	ch2_dut <= to_signed(234, DATA_WIDTH_IN);
	ch3_dut <= to_signed(325, DATA_WIDTH_IN);
	wait for clk_cyl;

	ch0_dut <= to_signed(-32768, DATA_WIDTH_IN);
	ch1_dut <= to_signed(-32768, DATA_WIDTH_IN);
	ch2_dut <= to_signed(32767, DATA_WIDTH_IN);
	ch3_dut <= to_signed(0, DATA_WIDTH_IN);
	wait for clk_cyl;

-----------FOR OVF_04 AND OVF_05

	ch0_dut <= to_signed(-32768, DATA_WIDTH_IN);
	ch1_dut <= to_signed(0, DATA_WIDTH_IN);
	ch2_dut <= to_signed(0, DATA_WIDTH_IN);
	ch3_dut <= to_signed(0, DATA_WIDTH_IN);
	wait for clk_cyl;

	ch0_dut <= to_signed(-34, DATA_WIDTH_IN);
	ch1_dut <= to_signed(8973, DATA_WIDTH_IN);
	ch2_dut <= to_signed(7243, DATA_WIDTH_IN);
	ch3_dut <= to_signed(20743, DATA_WIDTH_IN);
	wait for clk_cyl;

	ch0_dut <= to_signed(-323, DATA_WIDTH_IN);
	ch1_dut <= to_signed(1, DATA_WIDTH_IN);
	ch2_dut <= to_signed(32767, DATA_WIDTH_IN);
	ch3_dut <= to_signed(323, DATA_WIDTH_IN);
	wait for clk_cyl;

	ch0_dut <= to_signed(323, DATA_WIDTH_IN);
	ch1_dut <= to_signed(1, DATA_WIDTH_IN);
	ch2_dut <= to_signed(32767, DATA_WIDTH_IN);
	ch3_dut <= to_signed(-325, DATA_WIDTH_IN);
	wait for clk_cyl;

	ch0_dut <= to_signed(-32767, DATA_WIDTH_IN);
	ch1_dut <= to_signed(-1, DATA_WIDTH_IN);
	ch2_dut <= to_signed(0, DATA_WIDTH_IN);
	ch3_dut <= to_signed(-1, DATA_WIDTH_IN);
	wait for clk_cyl;

	ch0_dut <= to_signed(-34, DATA_WIDTH_IN);
	ch1_dut <= to_signed(8973, DATA_WIDTH_IN);
	ch2_dut <= to_signed(-9243, DATA_WIDTH_IN);
	ch3_dut <= to_signed(-20743, DATA_WIDTH_IN);
	wait for clk_cyl;

	ch0_dut <= to_signed(323, DATA_WIDTH_IN);
	ch1_dut <= to_signed(-1, DATA_WIDTH_IN);
	ch2_dut <= to_signed(-32767, DATA_WIDTH_IN);
	ch3_dut <= to_signed(-323, DATA_WIDTH_IN);
	wait for clk_cyl;

	ch0_dut <= to_signed(323, DATA_WIDTH_IN);
	ch1_dut <= to_signed(-1, DATA_WIDTH_IN);
	ch2_dut <= to_signed(-32767, DATA_WIDTH_IN);
	ch3_dut <= to_signed(-325, DATA_WIDTH_IN);
	wait for clk_cyl;

end process;

end architecture;
