library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity packet_length_tb is
end packet_length_tb;

architecture behavior of packet_length_tb is
    signal i_clk,i_valid,i_last, i_ready : std_logic := '0';
    signal received_packet_length : std_logic_vector(15 downto 0) := X"0004";
    signal o_packet_length_error : std_logic := '0';
    signal i_data : std_logic_vector(7 downto 0);

    component packet_length
    port(
        -- input ports
        i_clk, i_ready, i_valid, i_last : in std_logic;
        received_packet_length : in std_logic_vector(15 downto 0);
        -- output ports
        o_packet_length_error : out std_logic
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
    top_module: packet_length
        port map (
            i_clk => i_clk,
            i_ready => i_ready,
            i_valid => i_valid,
            i_last => i_last,
            received_packet_length => received_packet_length,
            o_packet_length_error => o_packet_length_error
        );

    process
    begin
        while True loop
           i_last  <= '0';
           i_ready <= '1';
           i_valid <= '1';
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

           i_last <= '1';

           wait for 10000 ns;

        end loop;
    end process;

    process
    begin
        wait for 1 ns;
        wait;
    end process;

end behavior;
