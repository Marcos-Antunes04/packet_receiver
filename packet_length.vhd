library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity packet_length is
    port(
        -- input ports
        i_clk, i_valid, i_last : in std_logic;
        o_ready : out std_logic;
        received_packet_length : in std_logic_vector(15 downto 0);
        -- output ports
        o_packet_length_error : out std_logic
    );
end packet_length;

architecture behavioral of packet_length is
    signal counter, next_counter : std_logic_vector(15 downto 0) := (others => '0');
begin

    process(i_clk, i_last) 
    begin
        if(falling_edge(i_last)) then
            counter <= (others => '0');
        elsif(rising_edge(i_clk) and not (i_valid = '0')) then
            counter <= next_counter;
        end if;
    end process;
    
    next_counter <= (others => '0') when counter = X"FFFF" else
                     std_logic_vector(unsigned(counter) + X"0001");

    o_packet_length_error <= '0' when i_last = '0' else
                             '1' when i_last = '1' and not (unsigned(counter) = unsigned(4 * unsigned(received_packet_length)));

end behavioral;
