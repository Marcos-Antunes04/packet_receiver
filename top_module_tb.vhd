library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity tb_top_module is
end tb_top_module;

architecture behavior of tb_top_module is
        signal slave_i_clk                     : std_logic := '0';
        signal S_AXIS_T_VALID                  : std_logic := '0';
        signal i_last                   : std_logic := '0';
        signal S_AXIS_T_READY                  : std_logic := '0';
        signal i_data                   : std_logic_vector(7 downto 0) := (others => '0');
        signal i_src_port                      : std_logic_vector(4 downto 0) := (others => '0');
        signal M_AXIS_TLAST                    : std_logic := '0';
        signal M_AXIS_TDATA                    : std_logic_vector(7 downto 0)  := (others => '0');
        signal master_o_dest_port              : std_logic_vector(04 downto 0) := (others => '0');
        signal master_o_dest_addr              : std_logic_vector(15 downto 0) := (others => '0');
        signal M_AXIS_TREADY : std_logic      := '0';
        signal M_AXIS_TVALID : std_logic      := '0';
        signal master_o_flags : std_logic_vector(6 downto 0) := (others => '0');


    component top_module
    port(
        -- slave interface ports
        slave_i_clk                     : in  std_logic;
        S_AXIS_T_VALID                  : in  std_logic;
        i_last                   : in  std_logic;
        S_AXIS_T_READY                  : out std_logic;
        i_data                   : in  std_logic_vector(7 downto 0);
        i_src_port                      : in  std_logic_vector(4 downto 0);
        M_AXIS_TREADY                   : in  std_logic;
        M_AXIS_TVALID                   : out std_logic;
        M_AXIS_TDATA                    : out std_logic_vector(7 downto 0);
        M_AXIS_TLAST                    : out std_logic := '0';
        master_o_dest_port              : out std_logic_vector(04 downto 0);
        master_o_dest_addr              : out std_logic_vector(15 downto 0);
        master_o_flags                  : out std_logic_vector(06 downto 0)
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
        clk <= '0';
    end procedure clock_cycle_with_data;

    procedure clock_cycle_with_last_data(signal clk : inout std_logic; signal last : inout std_logic; signal data : inout std_logic_vector;  value : std_logic_vector) is
    begin
        clk <= '0';
        last <= '1';
        wait for 1 ns;
        data <= value;
        wait for 1 ns;
        clk <= '1';
        wait for 2 ns;
        clk <= '0';
        last <= '0';
    end procedure clock_cycle_with_last_data;

begin
    master_module: top_module
        port map (
            slave_i_clk => slave_i_clk,
            S_AXIS_T_VALID => S_AXIS_T_VALID,
            i_last => i_last,
            S_AXIS_T_READY => S_AXIS_T_READY,
            i_src_port => i_src_port,
            i_data => i_data,
            M_AXIS_TDATA => M_AXIS_TDATA,
            master_o_dest_port => master_o_dest_port,
            master_o_dest_addr => master_o_dest_addr,
            M_AXIS_TLAST      => M_AXIS_TLAST,
            M_AXIS_TREADY => M_AXIS_TREADY,
            M_AXIS_TVALID => M_AXIS_TVALID,
            master_o_flags => master_o_flags
    );


    process
    begin
        while True loop
           i_src_port <= "00001";
           i_last <= '0';
           wait for 10 ns;

           -- conexão SA=1

           -- Packet length
           clock_cycle_with_data(slave_i_clk, i_data , X"00");
           clock_cycle_with_data(slave_i_clk, i_data , X"04");

           -- checksum
           clock_cycle_with_data(slave_i_clk, i_data , X"7F");
           clock_cycle_with_data(slave_i_clk, i_data , X"E1");

           -- seq_num
           clock_cycle_with_data(slave_i_clk, i_data , X"00");
           clock_cycle_with_data(slave_i_clk, i_data , X"00");
           clock_cycle_with_data(slave_i_clk, i_data , X"00");
           clock_cycle_with_data(slave_i_clk, i_data , X"01");

           -- clpr
           clock_cycle_with_data(slave_i_clk, i_data , X"80"); -- flag
           clock_cycle_with_data(slave_i_clk, i_data , X"18"); -- protocol

           -- dummy
           clock_cycle_with_data(slave_i_clk, i_data , X"00");
           clock_cycle_with_data(slave_i_clk, i_data , X"00");

           -- src_addr
           clock_cycle_with_data(slave_i_clk, i_data , X"00");
           clock_cycle_with_data(slave_i_clk, i_data , X"01");

           -- dest_addr
           clock_cycle_with_data(slave_i_clk, i_data , X"00");
           clock_cycle_with_last_data(slave_i_clk, i_last, i_data , X"00");
           
           wait for 5 ns;
           i_src_port <= "00010";
           wait for 5 ns;

           -- conexão SA=2

           -- Packet length
           clock_cycle_with_data(slave_i_clk, i_data , X"00");
           clock_cycle_with_data(slave_i_clk, i_data , X"04");

           -- checksum
           clock_cycle_with_data(slave_i_clk, i_data , X"7F");
           clock_cycle_with_data(slave_i_clk, i_data , X"DC");

           -- seq_num
           clock_cycle_with_data(slave_i_clk, i_data , X"00");
           clock_cycle_with_data(slave_i_clk, i_data , X"00");
           clock_cycle_with_data(slave_i_clk, i_data , X"00");
           clock_cycle_with_data(slave_i_clk, i_data , X"05");

           -- clpr
           clock_cycle_with_data(slave_i_clk, i_data , X"80"); -- flag
           clock_cycle_with_data(slave_i_clk, i_data , X"18"); -- protocol

           -- dummy
           clock_cycle_with_data(slave_i_clk, i_data , X"00");
           clock_cycle_with_data(slave_i_clk, i_data , X"00");

           -- src_addr
           clock_cycle_with_data(slave_i_clk, i_data , X"00");
           clock_cycle_with_data(slave_i_clk, i_data , X"02");

           -- dest_addr
           clock_cycle_with_data(slave_i_clk, i_data , X"00");
           clock_cycle_with_last_data(slave_i_clk, i_last, i_data , X"00");
           
           wait for 5 ns;
           i_src_port <= "00001";
           wait for 15 ns;

            -- new transmission
            -- envio de SA=1 para DA=2

           clock_cycle_with_data(slave_i_clk, i_data , X"00");
           clock_cycle_with_data(slave_i_clk, i_data , X"07");

           -- checksum
           clock_cycle_with_data(slave_i_clk, i_data , X"AD");
           clock_cycle_with_data(slave_i_clk, i_data , X"EC");

           -- seq_num
           clock_cycle_with_data(slave_i_clk, i_data , X"00");
           clock_cycle_with_data(slave_i_clk, i_data , X"00");
           clock_cycle_with_data(slave_i_clk, i_data , X"00");
           clock_cycle_with_data(slave_i_clk, i_data , X"03");

           -- clpr
           clock_cycle_with_data(slave_i_clk, i_data , X"00"); -- flag
           clock_cycle_with_data(slave_i_clk, i_data , X"18"); -- protocol

           -- dummy
           clock_cycle_with_data(slave_i_clk, i_data , X"00");
           clock_cycle_with_data(slave_i_clk, i_data , X"00");

           -- src_addr
           clock_cycle_with_data(slave_i_clk, i_data , X"00");
           clock_cycle_with_data(slave_i_clk, i_data , X"01");

           -- dest_addr
           clock_cycle_with_data(slave_i_clk, i_data , X"00");
           clock_cycle_with_data(slave_i_clk, i_data , X"02");

           -- payload

           clock_cycle_with_data(slave_i_clk, i_data , X"48");
           clock_cycle_with_data(slave_i_clk, i_data , X"65");
           clock_cycle_with_data(slave_i_clk, i_data , X"6C");
           clock_cycle_with_data(slave_i_clk, i_data , X"6C");
           clock_cycle_with_data(slave_i_clk, i_data , X"6F");
           clock_cycle_with_data(slave_i_clk, i_data , X"20");
           clock_cycle_with_data(slave_i_clk, i_data , X"57");
           clock_cycle_with_data(slave_i_clk, i_data , X"6F");
           clock_cycle_with_data(slave_i_clk, i_data , X"72");
           clock_cycle_with_data(slave_i_clk, i_data , X"6C");
           clock_cycle_with_data(slave_i_clk, i_data , X"64");
           clock_cycle_with_last_data(slave_i_clk, i_last, i_data , X"21");

           wait for 10 ns;    

           M_AXIS_TREADY <= '1';
           clock_cycle_with_data(slave_i_clk, i_data , X"00");
           clock_cycle_with_data(slave_i_clk, i_data , X"00");
           clock_cycle_with_data(slave_i_clk, i_data , X"00");
           clock_cycle_with_data(slave_i_clk, i_data , X"00");
           clock_cycle_with_data(slave_i_clk, i_data , X"00");
           clock_cycle_with_data(slave_i_clk, i_data , X"00");
           clock_cycle_with_data(slave_i_clk, i_data , X"00");
           clock_cycle_with_data(slave_i_clk, i_data , X"00");
           clock_cycle_with_data(slave_i_clk, i_data , X"00");
           clock_cycle_with_data(slave_i_clk, i_data , X"00");
           M_AXIS_TREADY <= '0';


           wait for 5 ns;
           wait for 5 ns;
           i_src_port <= "00010";
           wait for 15 ns;

            -- new transmission
            -- envio de SA=2 para DA=1

           clock_cycle_with_data(slave_i_clk, i_data , X"00");
           clock_cycle_with_data(slave_i_clk, i_data , X"07");

           -- checksum
           clock_cycle_with_data(slave_i_clk, i_data , X"10");
           clock_cycle_with_data(slave_i_clk, i_data , X"86");

           -- seq_num
           clock_cycle_with_data(slave_i_clk, i_data , X"00");
           clock_cycle_with_data(slave_i_clk, i_data , X"00");
           clock_cycle_with_data(slave_i_clk, i_data , X"00");
           clock_cycle_with_data(slave_i_clk, i_data , X"06");

           -- clpr
           clock_cycle_with_data(slave_i_clk, i_data , X"00"); -- flag
           clock_cycle_with_data(slave_i_clk, i_data , X"18"); -- protocol

           -- dummy
           clock_cycle_with_data(slave_i_clk, i_data , X"00");
           clock_cycle_with_data(slave_i_clk, i_data , X"00");

           -- src_addr
           clock_cycle_with_data(slave_i_clk, i_data , X"00");
           clock_cycle_with_data(slave_i_clk, i_data , X"02");

           -- dest_addr
           clock_cycle_with_data(slave_i_clk, i_data , X"00");
           clock_cycle_with_data(slave_i_clk, i_data , X"01");

           -- payload

           clock_cycle_with_data(slave_i_clk, i_data , X"21");
           clock_cycle_with_data(slave_i_clk, i_data , X"64");
           clock_cycle_with_data(slave_i_clk, i_data , X"6C");
           clock_cycle_with_data(slave_i_clk, i_data , X"72");
           clock_cycle_with_data(slave_i_clk, i_data , X"6F");
           clock_cycle_with_data(slave_i_clk, i_data , X"57");
           clock_cycle_with_data(slave_i_clk, i_data , X"20");
           clock_cycle_with_data(slave_i_clk, i_data , X"6F");
           clock_cycle_with_data(slave_i_clk, i_data , X"6C");
           clock_cycle_with_data(slave_i_clk, i_data , X"6C");
           clock_cycle_with_data(slave_i_clk, i_data , X"65");
           clock_cycle_with_last_data(slave_i_clk, i_last, i_data , X"48");

           wait for 5 ns;
           wait for 5 ns;
           i_src_port <= "00001";
           wait for 15 ns;

            -- new transmission
            -- desconexão de SA=1

           clock_cycle_with_data(slave_i_clk, i_data, X"00");
           clock_cycle_with_data(slave_i_clk, i_data, X"04");

           -- checksum
           clock_cycle_with_data(slave_i_clk, i_data, X"FE");
           clock_cycle_with_data(slave_i_clk, i_data, X"DF");

           -- seq_num
           clock_cycle_with_data(slave_i_clk, i_data, X"00");
           clock_cycle_with_data(slave_i_clk, i_data, X"00");
           clock_cycle_with_data(slave_i_clk, i_data, X"00");
           clock_cycle_with_data(slave_i_clk, i_data, X"03");

           -- clpr
           clock_cycle_with_data(slave_i_clk, i_data, X"01"); -- flag
           clock_cycle_with_data(slave_i_clk, i_data, X"18"); -- protocol

           -- dummy
           clock_cycle_with_data(slave_i_clk, i_data, X"00");
           clock_cycle_with_data(slave_i_clk, i_data, X"00");

           -- src_addr
           clock_cycle_with_data(slave_i_clk, i_data, X"00");
           clock_cycle_with_data(slave_i_clk, i_data, X"01");

           -- dest_addr
           clock_cycle_with_data(slave_i_clk, i_data, X"00");
           clock_cycle_with_last_data(slave_i_clk, i_last, i_data, X"00");

           wait for 5 ns;
           wait for 5 ns;
           i_src_port <= "00010";
           wait for 15 ns;

            -- new transmission
            -- desconexão de SA=2

           clock_cycle_with_data(slave_i_clk, i_data, X"00");
           clock_cycle_with_data(slave_i_clk, i_data, X"04");

           -- checksum
           clock_cycle_with_data(slave_i_clk, i_data, X"FE");
           clock_cycle_with_data(slave_i_clk, i_data, X"DA");

           -- seq_num
           clock_cycle_with_data(slave_i_clk, i_data, X"00");
           clock_cycle_with_data(slave_i_clk, i_data, X"00");
           clock_cycle_with_data(slave_i_clk, i_data, X"00");
           clock_cycle_with_data(slave_i_clk, i_data, X"07");

           -- clpr
           clock_cycle_with_data(slave_i_clk, i_data, X"01"); -- flag
           clock_cycle_with_data(slave_i_clk, i_data, X"18"); -- protocol

           -- dummy
           clock_cycle_with_data(slave_i_clk, i_data, X"00");
           clock_cycle_with_data(slave_i_clk, i_data, X"00");

           -- src_addr
           clock_cycle_with_data(slave_i_clk, i_data, X"00");
           clock_cycle_with_data(slave_i_clk, i_data, X"02");

           -- dest_addr
           clock_cycle_with_data(slave_i_clk, i_data, X"00");
           clock_cycle_with_last_data(slave_i_clk, i_last, i_data, X"00");

           wait for 5 ns;
           wait for 5 ns;
           wait for 15 ns;

           wait for 10000 ns;
        end loop;
    end process;

    process
    begin
        S_AXIS_T_READY <= '1';
        S_AXIS_T_VALID <= '1';
        wait for 1 ns;

        S_AXIS_T_READY <= '0';
        S_AXIS_T_VALID <= '0';
        wait for 1 ns;

        S_AXIS_T_READY <= '1';
        S_AXIS_T_VALID <= '1';
        wait for 1000 ns;

        wait;
    end process;

end behavior;
