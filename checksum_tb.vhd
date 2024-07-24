library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity checksum_tb is
end checksum_tb;

architecture behavior of checksum_tb is
    signal i_clk,valid,last, ready : std_logic := '0';
    signal i_data : std_logic_vector(7 downto 0) := "00000000";
    signal o_flag : std_logic;

    component checksum_RTL
    port(
        -- input ports
        i_clk, ready , valid, last : in std_logic;
        i_data : in std_logic_vector(7 downto 0);
        -- output ports        
        o_flag : out std_logic
    );
    end component;

    procedure clock_cycle_with_data(signal clk : inout std_logic; signal data : inout std_logic_vector; value : std_logic_vector) is
    begin
        clk <= '0';
        wait for 1 ns;
        data <= value;
        wait for 1 ns;
        clk <= '1';
        wait for 2 ns;
    end procedure clock_cycle_with_data;

begin
    top_module: checksum_RTL
        port map (
            i_clk => i_clk,
            ready => ready,
            valid => valid,
            last => last,
            i_data => i_data,
            o_flag => o_flag
        );

    process
    begin
        while True loop
           last  <= '0';
           ready <= '1';
           valid <= '1';
           wait for 10 ns;
           -- Packet length
           clock_cycle_with_data(i_clk, i_data , X"00");
           clock_cycle_with_data(i_clk, i_data , X"04");

           -- checksum
           clock_cycle_with_data(i_clk, i_data , X"7F");
           clock_cycle_with_data(i_clk, i_data , X"E1");

           -- seq_num
           clock_cycle_with_data(i_clk, i_data , X"00");
           clock_cycle_with_data(i_clk, i_data , X"00");
           clock_cycle_with_data(i_clk, i_data , X"00");
           clock_cycle_with_data(i_clk, i_data , X"01");

           -- clpr
           clock_cycle_with_data(i_clk, i_data , X"80"); -- flag
           clock_cycle_with_data(i_clk, i_data , X"18"); -- protocol

           -- dummy
           clock_cycle_with_data(i_clk, i_data , X"00");
           clock_cycle_with_data(i_clk, i_data , X"00");

           -- src_addr
           clock_cycle_with_data(i_clk, i_data , X"00");
           clock_cycle_with_data(i_clk, i_data , X"01");

           -- dest_addr
           clock_cycle_with_data(i_clk, i_data , X"00");
           clock_cycle_with_data(i_clk, i_data , X"00");
--           clock_cycle_with_data(i_clk, i_data , X"01");
           wait for 10 ns;

           last <= '1';

           wait for 10000 ns;

        end loop;
    end process;

    process
    begin
        wait for 1 ns;
        wait;
    end process;

end behavior;
