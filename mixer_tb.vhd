library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

use work.gain_calculate_pkg.all;

entity mixer_tb is 
generic (data_width_in: natural := 16;
	data_width_gain: natural := 10;
	data_width_out: natural := 24;
	num_state: natural := 18);
end entity;

architecture stimuli of mixer_tb is
-- DUT declaration
component mixer_datapath is
generic (num_state: natural := 7);
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
end component;

signal data_in_dut: signed(DATA_WIDTH_IN-1 downto 0);

signal gain_ctrA0_dut: unsigned(GAIN_WIDTH_IN-1 downto 0);
signal gain_ctrA1_dut: unsigned(GAIN_WIDTH_IN-1 downto 0);
signal gain_ctrA2_dut: unsigned(GAIN_WIDTH_IN-1 downto 0);
signal gain_ctrA3_dut: unsigned(GAIN_WIDTH_IN-1 downto 0);

signal gain_ctrB0_dut: unsigned(GAIN_WIDTH_IN-1 downto 0);
signal gain_ctrB1_dut: unsigned(GAIN_WIDTH_IN-1 downto 0);
signal gain_ctrB2_dut: unsigned(GAIN_WIDTH_IN-1 downto 0);
signal gain_ctrB3_dut: unsigned(GAIN_WIDTH_IN-1 downto 0);

signal gain_ctrMA_dut: unsigned(GAIN_WIDTH_IN-1 downto 0);
signal gain_ctrMB_dut: unsigned(GAIN_WIDTH_IN-1 downto 0);

signal data_out_dut: signed(DATA_WIDTH_OUT-1 downto 0);
signal over_flow_out_dut: signed(1 downto 0);

signal  clk_dut: std_logic := '0';

--96MHz clock
constant clk_cyl: time := 10.4 ns;

--File handling
file fInput: text;
file fOutput: text;

begin
-- DUT instantiation
dut: mixer_datapath
	port map(
	data_in => data_in_dut,

	gain_ctrA0 => gain_ctrA0_dut,
	gain_ctrA1 => gain_ctrA1_dut,
	gain_ctrA2 => gain_ctrA2_dut,
	gain_ctrA3 => gain_ctrA3_dut,

	gain_ctrB0 => gain_ctrB0_dut,
	gain_ctrB1 => gain_ctrB1_dut,
	gain_ctrB2 => gain_ctrB2_dut,
	gain_ctrB3 => gain_ctrB3_dut,

	gain_ctrMA => gain_ctrMA_dut,
	gain_ctrMB => gain_ctrMB_dut,

	data_out => data_out_dut,
	over_flow_out => over_flow_out_dut,

	clk => clk_dut);

clk_dut <= not clk_dut after clk_cyl/2;

stimuli: process
	variable inLine: line;
	variable outLine: line;
	variable lContent: string(1 to 19); 
	variable tempDataIn: std_logic_vector(DATA_WIDTH_IN-1 downto 0);
	variable tempLvlIn: std_logic_vector(GAIN_WIDTH_IN+1 downto 0);
	variable ch: character;
	variable int_out: integer;
begin
	file_open(fInput, "mixer_data_in.txt", read_mode);
	file_open(fOutput, "mixer_data_out.txt", write_mode);
	while not endfile(fInput) loop
		readline(fInput, inLine);

		--provide the gain A0, A1, A2, A3
		hread(inLine, tempLvlIn);
		gain_ctrA0_dut <= unsigned(tempLvlIn(GAIN_WIDTH_IN-1 downto 0));
		read(inLine, ch);
		hread(inLine, tempLvlIn);
		gain_ctrA1_dut <= unsigned(tempLvlIn(GAIN_WIDTH_IN-1 downto 0));
		read(inLine, ch);
		hread(inLine, tempLvlIn);
		gain_ctrA2_dut <= unsigned(tempLvlIn(GAIN_WIDTH_IN-1 downto 0));
		read(inLine, ch);
		hread(inLine, tempLvlIn);
		gain_ctrA3_dut <= unsigned(tempLvlIn(GAIN_WIDTH_IN-1 downto 0));
		read(inLine, ch);

		--provide the gain B0, B1, B2, B3
		hread(inLine, tempLvlIn);
		gain_ctrB0_dut <= unsigned(tempLvlIn(GAIN_WIDTH_IN-1 downto 0));
		read(inLine, ch);
		hread(inLine, tempLvlIn);
		gain_ctrB1_dut <= unsigned(tempLvlIn(GAIN_WIDTH_IN-1 downto 0));
		read(inLine, ch);
		hread(inLine, tempLvlIn);
		gain_ctrB2_dut <= unsigned(tempLvlIn(GAIN_WIDTH_IN-1 downto 0));
		read(inLine, ch);
		hread(inLine, tempLvlIn);
		gain_ctrB3_dut <= unsigned(tempLvlIn(GAIN_WIDTH_IN-1 downto 0));
		read(inLine, ch);

		--provide the gain MA, MB
		hread(inLine, tempLvlIn);
		gain_ctrMA_dut <= unsigned(tempLvlIn(GAIN_WIDTH_IN-1 downto 0));
		read(inLine, ch);
		hread(inLine, tempLvlIn);
		gain_ctrMB_dut <= unsigned(tempLvlIn(GAIN_WIDTH_IN-1 downto 0));

		--provide data in
		hread(inLine, tempDataIn);
		data_in_dut <= signed(tempDataIn);
		read(inLine, ch);
		
		--wait until the calculation on finish 4 clocks with frequency 192KHz
		wait for 4*500*clk_cyl;
		
		--update data to the text file
		int_out := to_integer(data_out_dut);
		write(outLine, int_out, left, 4);
		writeline(fOutput, outLine);

	end loop;

	file_close(fInput);
	file_close(fOutput);

	wait;

end process;

end architecture;