library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_top_module is
end tb_top_module;

architecture behavior of tb_top_module is
        signal slave_i_clk, slave_i_valid, slave_i_last : std_logic := '0';
        signal slave_o_ready : std_logic := '0';
        signal slave_i_data : std_logic_vector(7 downto 0) := (others => '0');
        signal i_src_port : std_logic_vector(4 downto 0) := (others => '0');
        signal o_dest_port_valid : std_logic := '0';
        signal i_dest_port_ready :  std_logic := '0';
        signal o_dest_addr_valid :  std_logic := '0';
        signal i_dest_addr_ready :  std_logic := '0';
        signal o_calc_checksum_valid : std_logic := '0';
        signal i_calc_checksum_ready :  std_logic := '0';
        signal o_flags_valid : std_logic := '0';
        signal i_flags_ready :  std_logic := '0';
        signal master_o_clock : std_logic := '0';
        signal master_o_data : std_logic_vector(7 downto 0) := (others => '0');

    component top_module
    port(
        -- slave interface ports
        slave_i_clk, slave_i_valid, slave_i_last : in std_logic;
        slave_o_ready : out std_logic;
        slave_i_data : in std_logic_vector(7 downto 0);
        i_src_port : in std_logic_vector(4 downto 0);

        -- master interface ports

        -- controle da transmissão de dest_port
        o_dest_port_valid : out std_logic;
        i_dest_port_ready : in  std_logic;
        -- controle da transmissão de dest_addr
        o_dest_addr_valid : out std_logic;
        i_dest_addr_ready : in  std_logic;
        -- controle da transmissão de checksum
        o_calc_checksum_valid : out std_logic;
        i_calc_checksum_ready : in  std_logic;
        -- controle da transmissão de flags
        o_flags_valid : out std_logic;
        i_flags_ready : in  std_logic;
        
        master_o_clock : out std_logic;
        master_o_data : out std_logic_vector(7 downto 0)
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
    master_module: top_module
        port map (
            slave_i_clk => slave_i_clk,
            slave_i_valid => slave_i_valid,
            slave_i_last => slave_i_last,
            slave_o_ready => slave_o_ready,
            i_src_port => i_src_port,
            slave_i_data => slave_i_data,
            o_dest_port_valid => o_dest_port_valid,
            i_dest_port_ready => i_dest_port_ready,
            o_dest_addr_valid => o_dest_addr_valid,
            i_dest_addr_ready => i_dest_addr_ready,
            o_calc_checksum_valid => o_calc_checksum_valid,
            i_calc_checksum_ready => i_calc_checksum_ready,
            o_flags_valid => o_flags_valid, 
            i_flags_ready => i_flags_ready, 
            master_o_clock => master_o_clock,
            master_o_data => master_o_data
    );


    process
    begin
        while True loop
           i_src_port <= "00001";
           slave_i_last <= '0';
           wait for 10 ns;

           -- conexão SA=1

           -- Packet length
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"00");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"04");

           -- checksum
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"7F");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"E1");

           -- seq_num
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"00");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"00");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"00");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"01");

           -- clpr
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"80"); -- flag
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"18"); -- protocol

           -- dummy
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"00");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"00");

           -- src_addr
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"00");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"01");

           -- dest_addr
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"00");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"00");
           
           wait for 15 ns;
           slave_i_last <= '1';
           wait for 10 ns;
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"00");
           wait for 10 ns;
           slave_i_last <= '0';
           i_src_port <= "00010";
           wait for 20 ns;


           -- conexão SA=2

           -- Packet length
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"00");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"04");

           -- checksum
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"7F");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"DC");

           -- seq_num
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"00");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"00");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"00");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"05");

           -- clpr
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"80"); -- flag
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"18"); -- protocol

           -- dummy
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"00");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"00");

           -- src_addr
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"00");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"02");

           -- dest_addr
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"00");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"00");
           
           wait for 15 ns;
           slave_i_last <= '1';
           wait for 10 ns;
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"00");
           wait for 10 ns;
           slave_i_last <= '0';
           i_src_port <= "00001";
           wait for 20 ns;


            -- new transmission
            -- envio de SA=1 para DA=2

           clock_cycle_with_data(slave_i_clk, slave_i_data , X"00");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"07");

           -- checksum
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"AD");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"EC");

           -- seq_num
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"00");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"00");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"00");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"02");

           -- clpr
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"00"); -- flag
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"18"); -- protocol

           -- dummy
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"00");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"00");

           -- src_addr
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"00");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"01");

           -- dest_addr
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"00");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"02");

           -- payload

           clock_cycle_with_data(slave_i_clk, slave_i_data , X"48");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"65");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"6C");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"6C");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"6F");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"20");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"57");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"6F");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"72");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"6C");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"64");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"21");

           wait for 15 ns;
           slave_i_last <= '1';
           wait for 20 ns;
           slave_i_last <= '0';
           i_src_port <= "00010";
           wait for 20 ns;

            -- new transmission
            -- envio de SA=2 para DA=1

           clock_cycle_with_data(slave_i_clk, slave_i_data , X"00");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"07");

           -- checksum
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"10");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"86");

           -- seq_num
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"00");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"00");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"00");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"06");

           -- clpr
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"00"); -- flag
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"18"); -- protocol

           -- dummy
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"00");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"00");

           -- src_addr
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"00");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"02");

           -- dest_addr
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"00");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"01");

           -- payload

           clock_cycle_with_data(slave_i_clk, slave_i_data , X"21");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"64");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"6C");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"72");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"6F");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"57");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"20");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"6F");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"6C");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"6C");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"65");
           clock_cycle_with_data(slave_i_clk, slave_i_data , X"48");

           wait for 15 ns;
           slave_i_last <= '1';
           wait for 20 ns;
           slave_i_last <= '0';
           i_src_port <= "00001";
           wait for 20 ns;

            -- new transmission
            -- desconexão de SA=1

           clock_cycle_with_data(slave_i_clk, slave_i_data, X"00");
           clock_cycle_with_data(slave_i_clk, slave_i_data, X"04");

           -- checksum
           clock_cycle_with_data(slave_i_clk, slave_i_data, X"FE");
           clock_cycle_with_data(slave_i_clk, slave_i_data, X"DF");

           -- seq_num
           clock_cycle_with_data(slave_i_clk, slave_i_data, X"00");
           clock_cycle_with_data(slave_i_clk, slave_i_data, X"00");
           clock_cycle_with_data(slave_i_clk, slave_i_data, X"00");
           clock_cycle_with_data(slave_i_clk, slave_i_data, X"03");

           -- clpr
           clock_cycle_with_data(slave_i_clk, slave_i_data, X"01"); -- flag
           clock_cycle_with_data(slave_i_clk, slave_i_data, X"18"); -- protocol

           -- dummy
           clock_cycle_with_data(slave_i_clk, slave_i_data, X"00");
           clock_cycle_with_data(slave_i_clk, slave_i_data, X"00");

           -- src_addr
           clock_cycle_with_data(slave_i_clk, slave_i_data, X"00");
           clock_cycle_with_data(slave_i_clk, slave_i_data, X"01");

           -- dest_addr
           clock_cycle_with_data(slave_i_clk, slave_i_data, X"00");
           clock_cycle_with_data(slave_i_clk, slave_i_data, X"00");

            wait for 15 ns;
           slave_i_last <= '1';
           wait for 20 ns;
           slave_i_last <= '0';
           i_src_port <= "00010";
           wait for 20 ns;

            -- new transmission
            -- desconexão de SA=2

           clock_cycle_with_data(slave_i_clk, slave_i_data, X"00");
           clock_cycle_with_data(slave_i_clk, slave_i_data, X"04");

           -- checksum
           clock_cycle_with_data(slave_i_clk, slave_i_data, X"FE");
           clock_cycle_with_data(slave_i_clk, slave_i_data, X"DA");

           -- seq_num
           clock_cycle_with_data(slave_i_clk, slave_i_data, X"00");
           clock_cycle_with_data(slave_i_clk, slave_i_data, X"00");
           clock_cycle_with_data(slave_i_clk, slave_i_data, X"00");
           clock_cycle_with_data(slave_i_clk, slave_i_data, X"07");

           -- clpr
           clock_cycle_with_data(slave_i_clk, slave_i_data, X"01"); -- flag
           clock_cycle_with_data(slave_i_clk, slave_i_data, X"18"); -- protocol

           -- dummy
           clock_cycle_with_data(slave_i_clk, slave_i_data, X"00");
           clock_cycle_with_data(slave_i_clk, slave_i_data, X"00");

           -- src_addr
           clock_cycle_with_data(slave_i_clk, slave_i_data, X"00");
           clock_cycle_with_data(slave_i_clk, slave_i_data, X"02");

           -- dest_addr
           clock_cycle_with_data(slave_i_clk, slave_i_data, X"00");
           clock_cycle_with_data(slave_i_clk, slave_i_data, X"00");

           wait for 15 ns;

           slave_i_last <= '1';
           wait for 10000 ns;
        end loop;
    end process;

    process
    begin
        slave_o_ready <= '1';
        slave_i_valid <= '1';
        -- i_last <= '0';
        wait for 1 ns;

        slave_o_ready <= '0';
        slave_i_valid <= '0';
        wait for 1 ns;

        slave_o_ready <= '1';
        slave_i_valid <= '1';
        wait for 1000 ns;

        wait;
    end process;

end behavior;
