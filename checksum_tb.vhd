library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity checksum_tb is
end checksum_tb;

architecture behavior of checksum_tb is
    signal i_clk,i_valid,i_last, i_ready : std_logic := '0';
    signal i_data : std_logic_vector(7 downto 0) := (others => '0');
    signal i_received_checksum : std_logic_vector(15 downto 0) := (others => '0');
    signal o_calc_checksum : std_logic_vector(15 downto 0) := (others => '0');
    signal o_flag : std_logic;

    component checksum
    port(
        -- input ports
        i_clk, i_ready , i_valid, i_last : in std_logic;
        i_data : in std_logic_vector(7 downto 0);
        i_received_checksum : in std_logic_vector(15 downto 0);
        -- output ports        
        o_calc_checksum : out std_logic_vector(15 downto 0);
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
    top_module: checksum
        port map (
            i_clk => i_clk,
            i_ready => i_ready,
            i_valid => i_valid,
            i_last => i_last,
            i_received_checksum => i_received_checksum,
            i_data => i_data,
            o_calc_checksum => o_calc_checksum,
            o_flag => o_flag
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
           i_received_checksum <= X"7FE1";
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
