library ieee;
use ieee.std_logic_1164.all;
entity xor2 is
    port(
        i1, i2 : in std_logic;
        o1 : out std_logic
    );
end xor2;

architecture arch of xor2 is
begin
    o1 <= i1 xor i2;
end arch;
