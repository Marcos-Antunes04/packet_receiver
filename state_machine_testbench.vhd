library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_state_machine is
end tb_state_machine;

architecture behavior of tb_state_machine is
    signal i_clk,i_valid,i_last : std_logic := '0';
    signal i_ready : std_logic := '1';
    signal i_data : std_logic_vector(7 downto 0) := "00000000";
    signal i_src_port, i_dest_port : std_logic_vector(4 downto 0) := "00000";
    signal o_ready, o_valid, o_last : std_logic := '0'; 
    signal o_data : std_logic_vector(7 downto 0) := "00000000";
    signal o_src_addr, o_dest_addr : std_logic_vector(15 downto 0) := "0000000000000000";
    signal o_flags : std_logic_vector(5 downto 0) := "000000";

    component state_machine
    port(
        -- input ports
        i_clk, i_ready, i_valid, i_last : in std_logic;
        i_data : in std_logic_vector(7 downto 0);
        i_src_port, i_dest_port: in std_logic_vector(4 downto 0);
        -- output ports        
        o_ready, o_valid, o_last : out std_logic; 
        o_data : out std_logic_vector(7 downto 0);
        o_src_addr, o_dest_addr : out std_logic_vector(15 downto 0);
        o_flags : out std_logic_vector(5 downto 0)
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
    uut: state_machine
        port map (
            i_clk => i_clk,
            i_ready => i_ready,
            i_valid => i_valid,
            i_last => i_last,
            i_src_port => i_src_port,
            i_dest_port => i_dest_port,
            i_data => i_data,
            o_ready => o_ready,
            o_valid => o_valid,
            o_last => o_last,
            o_src_addr => o_src_addr,
            o_dest_addr => o_dest_addr,
            o_flags => o_flags,
            o_data => o_data
    );


    process
    begin
        while True loop
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

        end loop;
    end process;

    process
    begin
        i_ready <= '1';
        wait for 1 ns;

        i_ready <= '0';
        wait for 1 ns;

        i_ready <= '1';
        wait for 1000 ns;

        wait;
    end process;

end behavior;
