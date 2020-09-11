library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.gain_calculate_pkg.all;

entity calculate is 
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
end entity;

architecture rtl of calculate is


signal data_0: signed(DATA_WIDTH_IN-1 downto 0);
signal gain_a0: unsigned(GAIN_WIDTH_IN-1 downto 0);

signal mul_rsl_a0: signed(DATA_WIDTH_IN+GAIN_WIDTH_IN downto 0);

begin

data_0 <= ch0;
gain_a0 <= a0;
mul_a0 <= mul_rsl_a0;

calculation: process(clk)
variable temp: signed(DATA_WIDTH_IN+1 downto 0);
begin
if rising_edge(clk) then
	--mul_rsl_a0 <= gainCal(data_0, gain_a0);
	temp := overFlowCal(ch0, ch1, ch2, ch3);
	add_rsl <= temp(DATA_WIDTH_IN-1 downto 0);
	over_flow_flg <= temp(DATA_WIDTH_IN+1 downto DATA_WIDTH_IN);
	
end if;
end process;

lim: process(mul_rsl_a0)
begin
	lim_16bit_mul_a0 <= limitResult(mul_rsl_a0);
	lim_24bit_mul_a0 <= limitFinalResult(mul_rsl_a0);
end process;

end architecture;