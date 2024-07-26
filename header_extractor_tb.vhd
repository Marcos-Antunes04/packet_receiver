library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity header_extractor_tb is
end header_extractor_tb;

architecture behavior of header_extractor_tb is
    signal i_clk,i_valid,i_last, o_ready : std_logic := '0';
    signal i_data          : std_logic_vector(7 downto 0)  := (others => '0');
    signal o_flag          : std_logic_vector(7 downto 0)  := (others => '0');
    signal o_packet_lenght : std_logic_vector(15 downto 0) := (others => '0');
    signal o_seq_num       : std_logic_vector(31 downto 0) := (others => '0');
    signal o_src_addr      : std_logic_vector(15 downto 0) := (others => '0');
    signal o_dest_addr     : std_logic_vector(15 downto 0) := (others => '0');
    signal o_checksum      : std_logic_vector(15 downto 0) := (others => '0');
    signal o_port_controller_clock : std_logic;

    component header_extractor
    port(
        -- input ports
        i_clk, i_valid, i_last : in std_logic;
        o_ready: out std_logic;
        i_data : in std_logic_vector(7 downto 0);
        -- output ports        
        o_packet_length : out std_logic_vector(15 downto 0) := (others => '0');
        o_flag          : out std_logic_vector(07 downto 0) := (others => '0');
        o_seq_num       : out std_logic_vector(31 downto 0) := (others => '0');
        o_src_addr      : out std_logic_vector(15 downto 0) := (others => '0');
        o_dest_addr     : out std_logic_vector(15 downto 0) := (others => '0');
        o_checksum      : out std_logic_vector(15 downto 0) := (others => '0');
        o_port_controller_clock : out std_logic := '0'
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
    top_module: header_extractor
        port map (
            i_clk           => i_clk,
            o_ready         => o_ready,
            i_valid         => i_valid,
            i_last          => i_last,
            i_data          => i_data,
            o_flag          => o_flag,
            o_packet_length => o_packet_lenght,
            o_seq_num       => o_seq_num,
            o_src_addr      => o_src_addr,
            o_dest_addr     => o_dest_addr,
            o_checksum      => o_checksum,
            o_port_controller_clock => o_port_controller_clock
        );

    process
    begin
        while True loop
           i_last  <= '0';
           o_ready <= '1';
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
