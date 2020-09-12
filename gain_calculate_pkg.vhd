library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package gain_calculate_pkg is

constant DATA_WIDTH_IN: natural := 16;
constant GAIN_WIDTH_IN: natural := 10;
constant DATA_WIDTH_OUT: natural := 24;
constant ONES: signed(DATA_WIDTH_IN-2 downto 0):= (others => '1');
constant ZEROS: signed(DATA_WIDTH_IN-2 downto 0):= (others => '0');
constant MIN_VAL: signed(DATA_WIDTH_IN-1 downto 0):= to_signed(-32768, DATA_WIDTH_IN);
constant MAX_VAL: signed(DATA_WIDTH_IN-1 downto 0):= to_signed(32767, DATA_WIDTH_IN);
constant OUT_MIN_VAL: signed(DATA_WIDTH_OUT-1 downto 0):= to_signed(16#800000#, DATA_WIDTH_OUT);
constant OUT_MAX_VAL: signed(DATA_WIDTH_OUT-1 downto 0):= to_signed(16#7FFFFF#, DATA_WIDTH_OUT);

subtype dataTyp is signed(DATA_WIDTH_IN-1 downto 0);
subtype gainTyp is unsigned(GAIN_WIDTH_IN-1 downto 0);
subtype mulResultTyp is signed(DATA_WIDTH_IN+GAIN_WIDTH_IN downto 0);
subtype addResultTyp is signed(DATA_WIDTH_IN+1 downto 0); --add first 2 bits for indication overflow of addition
subtype outputTyp is signed(DATA_WIDTH_OUT-1 downto 0);

function gainCal 	(dataIn: dataTyp; gainLvl: gainTyp)
			return mulResultTyp;

function limitResult	(dataIn: mulResultTyp)
			return dataTyp;

function limitFinalResult	(dataIn: mulResultTyp)
				return outputTyp;

function overFlowCal	(num1: dataTyp;
			num2: dataTyp;
			num3: dataTyp;
			num4: dataTyp)
			return addResultTyp;

end gain_calculate_pkg;

package body gain_calculate_pkg is

function gainCal 	(dataIn: dataTyp; gainLvl: gainTyp)
			return mulResultTyp
is
--For convinience when gain calculation result has the same type with dataIn, bit 11 always 0 -> value always positive
variable gain_cal: signed(GAIN_WIDTH_IN downto 0):= (others => '0');

variable temp: signed(DATA_WIDTH_IN+GAIN_WIDTH_IN downto 0):= (others => '0');

begin
--If gainLvl = 0 there is no gain the signal will keep the same
if (gainLvl=0 and dataIn >= 0) then return mulResultTyp("00000000000" & dataIn);

elsif (gainLvl=0 and dataIn < 0) then return mulResultTyp("11111111111" & dataIn);

--If gainLvl !=0, will consider gain or loss level
else
	for i in gainLvl'length-1 downto 0 loop
		--Bit 9-5 used for increasement (each bit will increase 32 times if all bits are set 
		--the increasement is 32+64+128+256+512=992 times approximaly +30dB(+1000 times)
		if(i=9 and gainLvl(i)='1') then gain_cal := gain_cal + 512;
		elsif(i=8 and gainLvl(i)='1') then gain_cal := gain_cal + 256;
		elsif(i=7 and gainLvl(i)='1') then gain_cal := gain_cal + 128;
		elsif(i=6 and gainLvl(i)='1') then gain_cal := gain_cal + 64;
		elsif(i=5 and gainLvl(i)='1') then gain_cal := gain_cal + 32;
		--Bit 4-0 used for decreasement (each bit will decrease 32 times if all bits are set 
		--the decreasement is 32+64+128+256+512=992 times approximaly -30dB(-1000 times)
		elsif(i=4 and gainLvl(i)='1') then gain_cal := gain_cal + 32;
		elsif(i=3 and gainLvl(i)='1') then gain_cal := gain_cal + 64;
		elsif(i=2 and gainLvl(i)='1') then gain_cal := gain_cal + 128;
		elsif(i=1 and gainLvl(i)='1') then gain_cal := gain_cal + 256;
		elsif(i=0 and gainLvl(i)='1') then gain_cal := gain_cal + 512;
		end if;
	end loop;
	--Signal gain
	if(gainLvl >= 2#0000100000#) then 
		temp:= to_signed(to_integer(dataIn*gain_cal), DATA_WIDTH_IN+GAIN_WIDTH_IN+1);
		return temp;
	--Signal loss
	elsif(gainLvl <= 2#0000011111#) then
		temp:= to_signed(to_integer(dataIn/gain_cal), DATA_WIDTH_IN+GAIN_WIDTH_IN+1);
		return temp;
	end if;
	return temp;
end if; --gainLvl=0

end gainCal;

function limitResult	(dataIn: mulResultTyp)
			return dataTyp
is

variable result: dataTyp;

begin
if(dataIn < MIN_VAL) then
	result := MIN_VAL;
elsif(dataIn > MAX_VAL) then
	result:= MAX_VAL;
else result:= dataIn(DATA_WIDTH_IN+GAIN_WIDTH_IN) & dataIn(14 downto 0);
end if;
return result;

end limitResult;

function limitFinalResult	(dataIn: mulResultTyp)
				return outputTyp
is

variable result: outputTyp;

begin
if(dataIn < OUT_MIN_VAL) then
	result := OUT_MIN_VAL;
elsif(dataIn > OUT_MAX_VAL) then
	result:= OUT_MAX_VAL;
else result:= dataIn(DATA_WIDTH_IN+GAIN_WIDTH_IN) & dataIn(22 downto 0);
end if;
return result;

end limitFinalResult;


function overFlowCal	(num1: dataTyp;
			num2: dataTyp;
			num3: dataTyp;
			num4: dataTyp)
			return addResultTyp
is
variable temp: signed(DATA_WIDTH_IN+1 downto 0):= (others => '0');
variable numPos: std_logic_vector(7 downto 0) := (others => '0');
variable temp1: signed(DATA_WIDTH_IN-1 downto 0):= (others => '0'); --result of 2 numbers with different signs
variable temp2: signed(DATA_WIDTH_IN-1 downto 0):= (others => '0');
variable temp3: signed(DATA_WIDTH_IN-1 downto 0):= (others => '0');
variable result: addResultTyp:= (others => '0');
begin
temp:= ("00" & num1) + ("00" & num2) + ("00" & num3) + ("00" & num4);
if(num1 >= 0 and num2 >= 0 and num3 >= 0 and num4 >= 0) then
	if(temp(DATA_WIDTH_IN+1 downto DATA_WIDTH_IN-1) /= "000") then result:= "010" & ONES; return result;
	else result:= "00" & temp(DATA_WIDTH_IN-1 downto 0); return result;
	end if;
elsif(num1 < 0 and num2 < 0 and num3 < 0 and num4 < 0) then
	if(temp(DATA_WIDTH_IN+1 downto DATA_WIDTH_IN-1) /= "111") then result:= "101" & ZEROS; return result;
	else result:= "00" & temp(DATA_WIDTH_IN-1 downto 0); return result;
	end if;
--else return result;
else
	if(num1 >= 0) then numPos(0) := '1'; else numPos(4) := '1'; end if;
	if(num2 >= 0) then numPos(1) := '1'; else numPos(5) := '1'; end if;
	if(num3 >= 0) then numPos(2) := '1'; else numPos(6) := '1'; end if;
	if(num4 >= 0) then numPos(3) := '1'; else numPos(7) := '1'; end if;
	case numPos is
	when "10000111" => --num1, num2, num3: positive; num4: negative (+ + + -)
		temp1:= num1+num4; --(+ -)
		if(temp1 >= 0) then --num1+num4: positive (+)
			temp2:= temp1+num2; --num2: positve (+ +)
			if(temp2 < 0) then result:= "010" & ONES; return result; -- result of adding 2 positive numbers: negative --> overflow (+ + = -)
			else temp3:= temp2+num3; --num3: positive (+ +)
				if(temp3 < 0) then result:= "010" & ONES; return result; -- result of adding 2 positive numbers: negative --> overflow (+ + = -)
				else result:= "00" & temp(DATA_WIDTH_IN-1 downto 0); return result;
				end if;
			end if;
		else --num1+num4: negative
			temp2:= temp1+num2; --num2: positive (- +)
			if(temp2 >= 0) then
				temp3:= temp2+num3; --num3: positive (+ +)
				if(temp3 < 0) then result:= "010" & ONES; return result; -- result of adding 2 positive numbers: negative --> overflow (+ + = -)
				else result:= "00" & temp(DATA_WIDTH_IN-1 downto 0); return result;
				end if;
			else result:= "00" & temp(DATA_WIDTH_IN-1 downto 0); return result;
			end if;
		end if;
	when "01001011" => --num1, num2, num4: positive; num3: negative (+ + - +)
		temp1:= num1+num3; --(+ -)
		if(temp1 >= 0) then --num1+num3: positive (+)
			temp2:= temp1+num2; --num2: positve (+ +)
			if(temp2 < 0) then result:= "010" & ONES; return result; -- result of adding 2 positive numbers: negative --> overflow (+ + = -)
			else temp3:= temp2+num4; --num4: positive (+ +)
				if(temp3 < 0) then result:= "010" & ONES; return result; -- result of adding 2 positive numbers: negative --> overflow (+ + = -)
				else result:= "00" & temp(DATA_WIDTH_IN-1 downto 0); return result;
				end if;
			end if;
		else --num1+num3: negative
			temp2:= temp1+num2; --num2: positive (- +)
			if(temp2 >= 0) then
				temp3:= temp2+num4; --num3: positive (+ +)
				if(temp3 < 0) then result:= "010" & ONES; return result; -- result of adding 2 positive numbers: negative --> overflow (+ + = -)
				else result:= "00" & temp(DATA_WIDTH_IN-1 downto 0); return result;
				end if;
			else result:= "00" & temp(DATA_WIDTH_IN-1 downto 0); return result;
			end if;
		end if;
	when "00101101" => --num1, num3, num4: positive; num2: negative (+ - + +)
		temp1:= num1+num2; --(+ -)
		if(temp1 >= 0) then --num1+num4: positive (+)
			temp2:= temp1+num3; --num2: positve (+ +)
			if(temp2 < 0) then result:= "010" & ONES; return result; -- result of adding 2 positive numbers: negative --> overflow (+ + = -)
			else temp3:= temp2+num4; --num4: positive (+ +)
				if(temp3 < 0) then result:= "010" & ONES; return result; -- result of adding 2 positive numbers: negative --> overflow (+ + = -)
				else result:= "00" & temp(DATA_WIDTH_IN-1 downto 0); return result;
				end if;
			end if;
		else --num1+num4: negative
			temp2:= temp1+num3; --num3: positive (- +)
			if(temp2 >= 0) then
				temp3:= temp2+num4; --num3: positive (+ +)
				if(temp3 < 0) then result:= "010" & ONES; return result; -- result of adding 2 positive numbers: negative --> overflow (+ + = -)
				else result:= "00" & temp(DATA_WIDTH_IN-1 downto 0); return result;
				end if;
			else result:= "00" & temp(DATA_WIDTH_IN-1 downto 0); return result;
			end if;
		end if;
	when "00011110" => --num2, num3, num4: positive; num1: negative (- + + +)
		temp1:= num2+num1; --(+ -)
		if(temp1 >= 0) then --num2+num1: positive (+)
			temp2:= temp1+num3; --num3: positve (+ +)
			if(temp2 < 0) then result:= "010" & ONES; return result; -- result of adding 2 positive numbers: negative --> overflow (+ + = -)
			else temp3:= temp2+num4; --num4: positive (+ +)
				if(temp3 < 0) then result:= "010" & ONES; return result; -- result of adding 2 positive numbers: negative --> overflow (+ + = -)
				else result:= "00" & temp(DATA_WIDTH_IN-1 downto 0); return result;
				end if;
			end if;
		else --num2+num1: negative
			temp2:= temp1+num3; --num3: positive (- +)
			if(temp2 >= 0) then
				temp3:= temp2+num4; --num4: positive (+ +)
				if(temp3 < 0) then result:= "010" & ONES; return result; -- result of adding 2 positive numbers: negative --> overflow (+ + = -)
				else result:= "00" & temp(DATA_WIDTH_IN-1 downto 0); return result;
				end if;
			else result:= "00" & temp(DATA_WIDTH_IN-1 downto 0); return result;
			end if;
		end if;
	when "11000011" => --num1, num2: positive; num3, num4: negative (+ + - -)
		temp1:= num1+num3; --(+ -)
		temp2:= num2+num4; --(+ -)
		temp3:= temp1+temp2;
		if(temp1 >= 0 and temp2 >= 0) then --(+ +)
			if(temp3 < 0) then result:= "010" & ONES; return result; -- result of adding 2 positive numbers: negative --> overflow (+ + = -)
			else result:= "00" & temp(DATA_WIDTH_IN-1 downto 0); return result;
			end if;
		elsif(temp1 < 0 and temp2 < 0) then --(- -)
			if(temp3 >= 0) then result:= "101" & ZEROS; return result; -- result of adding 2 negative numbers: positive --> overflow (- - = +)
			else result:= "00" & temp(DATA_WIDTH_IN-1 downto 0); return result;
			end if;
		else result:= "00" & temp(DATA_WIDTH_IN-1 downto 0); return result;
		end if;
	when "10100101" => --num1, num3: positive; num2, num4: negative (+ - + -)
		temp1:= num1+num2; --(+ -)
		temp2:= num3+num4; --(+ -)
		temp3:= temp1+temp2;
		if(temp1 >= 0 and temp2 >= 0) then --(+ +)
			if(temp3 < 0) then result:= "010" & ONES; return result; -- result of adding 2 positive numbers: negative --> overflow (+ + = -)
			else result:= "00" & temp(DATA_WIDTH_IN-1 downto 0); return result;
			end if;
		elsif(temp1 < 0 and temp2 < 0) then --(- -)
			if(temp3 >= 0) then result:= "101" & ZEROS; return result; -- result of adding 2 negative numbers: positive --> overflow (- - = +)
			else result:= "00" & temp(DATA_WIDTH_IN-1 downto 0); return result;
			end if;
		else result:= "00" & temp(DATA_WIDTH_IN-1 downto 0); return result;
		end if;
	when "10010110" => --num2, num3: positive; num1, num4: negative (- + + -)
		temp1:= num1+num2; --(- +)
		temp2:= num3+num4; --(+ -)
		temp3:= temp1+temp2;
		if(temp1 >= 0 and temp2 >= 0) then --(+ +)
			if(temp3 < 0) then result:= "010" & ONES; return result; -- result of adding 2 positive numbers: negative --> overflow (+ + = -)
			else result:= "00" & temp(DATA_WIDTH_IN-1 downto 0); return result;
			end if;
		elsif(temp1 < 0 and temp2 < 0) then --(- -)
			if(temp3 >= 0) then result:= "101" & ZEROS; return result; -- result of adding 2 negative numbers: positive --> overflow (- - = +)
			else result:= "00" & temp(DATA_WIDTH_IN-1 downto 0); return result;
			end if;
		else result:= "00" & temp(DATA_WIDTH_IN-1 downto 0); return result;
		end if;
	when "01101001" => --num1, num4: positive; num2, num3: negative (+ - - +)
		temp1:= num1+num2; --(+ -)
		temp2:= num3+num4; --(- +)
		temp3:= temp1+temp2;
		if(temp1 >= 0 and temp2 >= 0) then --(+ +)
			if(temp3 < 0) then result:= "010" & ONES; return result; -- result of adding 2 positive numbers: negative --> overflow (+ + = -)
			else result:= "00" & temp(DATA_WIDTH_IN-1 downto 0); return result;
			end if;
		elsif(temp1 < 0 and temp2 < 0) then --(- -)
			if(temp3 >= 0) then result:= "101" & ZEROS; return result; -- result of adding 2 negative numbers: positive --> overflow (- - = +)
			else result:= "00" & temp(DATA_WIDTH_IN-1 downto 0); return result;
			end if;
		else result:= "00" & temp(DATA_WIDTH_IN-1 downto 0); return result;
		end if;
	when "01011010" => --num2, num4: positive; num1, num3: negative (- + - +)
		temp1:= num1+num2; --(- +)
		temp2:= num3+num4; --(- +)
		temp3:= temp1+temp2;
		if(temp1 >= 0 and temp2 >= 0) then --(+ +)
			if(temp3 < 0) then result:= "010" & ONES; return result; -- result of adding 2 positive numbers: negative --> overflow (+ + = -)
			else result:= "00" & temp(DATA_WIDTH_IN-1 downto 0); return result;
			end if;
		elsif(temp1 < 0 and temp2 < 0) then --(- -)
			if(temp3 >= 0) then result:= "101" & ZEROS; return result; -- result of adding 2 negative numbers: positive --> overflow (- - = +)
			else result:= "00" & temp(DATA_WIDTH_IN-1 downto 0); return result;
			end if;
		else result:= "00" & temp(DATA_WIDTH_IN-1 downto 0); return result;
		end if;
	when "00111100" => --num3, num4: positive; num1, num2: negative (- - + +)
		temp1:= num1+num3; --(- +)
		temp2:= num2+num4; --(- +)
		temp3:= temp1+temp2;
		if(temp1 >= 0 and temp2 >= 0) then --(+ +)
			if(temp3 < 0) then result:= "010" & ONES; return result; -- result of adding 2 positive numbers: negative --> overflow (+ + = -)
			else result:= "00" & temp(DATA_WIDTH_IN-1 downto 0); return result;
			end if;
		elsif(temp1 < 0 and temp2 < 0) then --(- -)
			if(temp3 >= 0) then result:= "101" & ZEROS; return result; -- result of adding 2 negative numbers: positive --> overflow (- - = +)
			else result:= "00" & temp(DATA_WIDTH_IN-1 downto 0); return result;
			end if;
		else result:= "00" & temp(DATA_WIDTH_IN-1 downto 0); return result;
		end if;
	when "01111000" => --num1, num2, num3: negative; num4: positive (- - - +)
		temp1:= num1+num4; --(+ -)
		if(temp1 < 0) then --num1+num4: negative (-)
			temp2:= temp1+num2; --num2: negative (- -)
			if(temp2 >= 0) then result:= "101" & ZEROS; return result; -- result of adding 2 negative numbers: positive --> overflow (- - = +)
			else temp3:= temp2+num3; --num3: negative (- -)
				if(temp3 >= 0) then result:= "101" & ZEROS; return result; -- result of adding 2 negative numbers: positive --> overflow (- - = +)
				else result:= "00" & temp(DATA_WIDTH_IN-1 downto 0); return result;
				end if;
			end if;
		else --num1+num4: positive
			temp2:= temp1+num2; --num2: negative (+ -)
			if(temp2 < 0) then
				temp3:= temp2+num3; --num3: negative (- -)
				if(temp3 >= 0) then result:= "101" & ZEROS; return result; -- result of adding 2 negative numbers: positive --> overflow (- - = +)
				else result:= "00" & temp(DATA_WIDTH_IN-1 downto 0); return result;
				end if;
			else result:= "00" & temp(DATA_WIDTH_IN-1 downto 0); return result;
			end if;
		end if;
	when "10110100" => --num1, num2, num4: negative; num3: positive (- - + -)
		temp1:= num1+num3; --(- +)
		if(temp1 < 0) then --num1+num3: negative (-)
			temp2:= temp1+num2; --num2: negative (- -)
			if(temp2 >= 0) then result:= "101" & ZEROS; return result; -- result of adding 2 negative numbers: positive --> overflow (- - = +)
			else temp3:= temp2+num4; --num4: negative (- -)
				if(temp3 >= 0) then result:= "101" & ZEROS; return result; -- result of adding 2 negative numbers: positive --> overflow (- - = +)
				else result:= "00" & temp(DATA_WIDTH_IN-1 downto 0); return result;
				end if;
			end if;
		else --num1+num3: positive
			temp2:= temp1+num2; --num2: negative (+ -)
			if(temp2 < 0) then
				temp3:= temp2+num4; --num4: negative (- -)
				if(temp3 >= 0) then result:= "101" & ZEROS; return result; -- result of adding 2 negative numbers: positive --> overflow (- - = +)
				else result:= "00" & temp(DATA_WIDTH_IN-1 downto 0); return result;
				end if;
			else result:= "00" & temp(DATA_WIDTH_IN-1 downto 0); return result;
			end if;
		end if;
	when "11010010" => --num2, num3, num4: negative; num2: positive (- + - -)
		temp1:= num1+num2; --(- +)
		if(temp1 < 0) then --num1+num2: negative (-)
			temp2:= temp1+num3; --num3: negative (- -)
			if(temp2 >= 0) then result:= "101" & ZEROS; return result; -- result of adding 2 negative numbers: positive --> overflow (- - = +)
			else temp3:= temp2+num4; --num4: negative (- -)
				if(temp3 >= 0) then result:= "101" & ZEROS; return result; -- result of adding 2 negative numbers: positive --> overflow (- - = +)
				else result:= "00" & temp(DATA_WIDTH_IN-1 downto 0); return result;
				end if;
			end if;
		else --num1+num2: positive
			temp2:= temp1+num3; --num3: negative (+ -)
			if(temp2 < 0) then
				temp3:= temp2+num4; --num4: negative (- -)
				if(temp3 >= 0) then result:= "101" & ZEROS; return result; -- result of adding 2 negative numbers: positive --> overflow (- - = +)
				else result:= "00" & temp(DATA_WIDTH_IN-1 downto 0); return result;
				end if;
			else result:= "00" & temp(DATA_WIDTH_IN-1 downto 0); return result;
			end if;
		end if;
	when "11100001" => --num2, num3, num4: negative; num1: positive (+ - - -)
		temp1:= num1+num2; --(- +)
		if(temp1 < 0) then --num1+num2: negative (-)
			temp2:= temp1+num3; --num3: negative (- -)
			if(temp2 >= 0) then result:= "101" & ZEROS; return result; -- result of adding 2 negative numbers: positive --> overflow (- - = +)
			else temp3:= temp2+num4; --num4: negative (- -)
				if(temp3 >= 0) then result:= "101" & ZEROS; return result; -- result of adding 2 negative numbers: positive --> overflow (- - = +)
				else result:= "00" & temp(DATA_WIDTH_IN-1 downto 0); return result;
				end if;
			end if;
		else --num1+num2: positive
			temp2:= temp1+num3; --num3: negative (+ -)
			if(temp2 < 0) then
				temp3:= temp2+num4; --num4: negative (- -)
				if(temp3 >= 0) then result:= "101" & ZEROS; return result; -- result of adding 2 negative numbers: positive --> overflow (- - = +)
				else result:= "00" & temp(DATA_WIDTH_IN-1 downto 0); return result;
				end if;
			else result:= "00" & temp(DATA_WIDTH_IN-1 downto 0); return result;
			end if;
		end if;
	when others =>
		result:= "00" & temp(DATA_WIDTH_IN-1 downto 0); return result;
	end case;
end if;
end overFlowCal;

end package body gain_calculate_pkg;