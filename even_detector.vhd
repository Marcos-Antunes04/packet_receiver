library ieee;
use ieee.std_logic_1164.all;
entity even_detector is
    port(
        a : in std_logic_vector(2 downto 0);
        even : out std_logic
    );
end even_detector;

architecture arch of even_detector is
component xor2
    port(
        i1, i2 : in std_logic;
        o1 : out std_logic
    );
end component;
component not1
    port(
        i1 : in std_logic;
        o1 : out std_logic
    );
end component;
signal sig1, sig2 : std_logic;
begin
    unitl: xor2
        port map (i1 => a(0), i2 => a(1), o1 => sig1);
    unit2: xor2
        port map (i1 => a(2), i2 => sig1, o1 => sig2);
    unit3: not1
        port map (i1 => sig2, o1 => even); 
end arch;

