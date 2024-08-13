library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_top_module is
end tb_top_module;

architecture behavior of tb_top_module is
        signal slave_i_clk           : std_logic := '0';
        signal S_AXIS_T_VALID        : std_logic := '0';
        signal S_AXIS_T_LAST         : std_logic := '0';
        signal S_AXIS_T_READY        : std_logic := '0';
        signal S_AXIS_T_DATA         : std_logic_vector(7 downto 0) := (others => '0');
        signal i_src_port            : std_logic_vector(4 downto 0) := (others => '0');
        signal master_o_last         : std_logic := '0';
        signal master_o_data         : std_logic_vector(7 downto 0)  := (others => '0');
        signal master_o_dest_port    : std_logic_vector(04 downto 0) := (others => '0');
        signal master_o_dest_addr    : std_logic_vector(15 downto 0) := (others => '0');
        signal o_calc_checksum_valid : std_logic := '0';
        signal i_calc_checksum_ready : std_logic := '0';
        signal o_seq_num_expected_valid : std_logic := '0';
        signal i_seq_num_expected_ready : std_logic := '0';
        signal o_payload_length_expected_valid : std_logic := '0';
        signal i_payload_length_expected_ready : std_logic := '0';
        signal master_i_ready : std_logic := '0';
        signal master_o_valid : std_logic := '0';
        signal master_o_flags : std_logic_vector(6 downto 0) := (others => '0');


    component top_module
    port(
        -- slave interface ports
        slave_i_clk                     : in  std_logic;
        S_AXIS_T_VALID                  : in  std_logic;
        S_AXIS_T_LAST                   : in  std_logic;
        S_AXIS_T_READY                  : out std_logic;
        S_AXIS_T_DATA                   : in  std_logic_vector(7 downto 0);
        i_src_port                      : in  std_logic_vector(4 downto 0);
        o_calc_checksum_valid           : out std_logic;
        i_calc_checksum_ready           : in  std_logic;
        o_seq_num_expected_valid        : out std_logic;
        i_seq_num_expected_ready        : in  std_logic;
        o_payload_length_expected_valid : out std_logic;
        i_payload_length_expected_ready : in  std_logic;
        master_i_ready                  : in  std_logic;
        master_o_valid                  : out std_logic;
        master_o_data                   : out std_logic_vector(7 downto 0);
        master_o_last                   : out std_logic := '0';
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
            S_AXIS_T_LAST => S_AXIS_T_LAST,
            S_AXIS_T_READY => S_AXIS_T_READY,
            i_src_port => i_src_port,
            S_AXIS_T_DATA => S_AXIS_T_DATA,
            master_o_data => master_o_data,
            master_o_dest_port => master_o_dest_port,
            master_o_dest_addr => master_o_dest_addr,
            master_o_last      => master_o_last,
            o_calc_checksum_valid => o_calc_checksum_valid,
            i_calc_checksum_ready => i_calc_checksum_ready,
            o_seq_num_expected_valid => o_seq_num_expected_valid,
            i_seq_num_expected_ready => i_seq_num_expected_ready,
            o_payload_length_expected_valid => o_payload_length_expected_valid,
            i_payload_length_expected_ready => i_payload_length_expected_ready,
            master_i_ready => master_i_ready,
            master_o_valid => master_o_valid
    );


    process
    begin
        while True loop
           i_src_port <= "00001";
           S_AXIS_T_LAST <= '0';
           wait for 10 ns;

           -- conexão SA=1

           -- Packet length
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"00");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"04");

           -- checksum
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"7F");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"E1");

           -- seq_num
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"00");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"00");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"00");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"01");

           -- clpr
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"80"); -- flag
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"18"); -- protocol

           -- dummy
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"00");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"00");

           -- src_addr
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"00");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"01");

           -- dest_addr
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"00");
           clock_cycle_with_last_data(slave_i_clk, S_AXIS_T_LAST, S_AXIS_T_DATA , X"00");
           
           wait for 5 ns;
           i_src_port <= "00010";
           wait for 5 ns;

           -- conexão SA=2

           -- Packet length
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"00");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"04");

           -- checksum
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"7F");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"DC");

           -- seq_num
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"00");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"00");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"00");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"05");

           -- clpr
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"80"); -- flag
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"18"); -- protocol

           -- dummy
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"00");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"00");

           -- src_addr
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"00");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"02");

           -- dest_addr
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"00");
           clock_cycle_with_last_data(slave_i_clk, S_AXIS_T_LAST, S_AXIS_T_DATA , X"00");
           
           wait for 5 ns;
           i_src_port <= "00001";
           wait for 15 ns;

            -- new transmission
            -- envio de SA=1 para DA=2

           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"00");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"07");

           -- checksum
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"AD");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"EC");

           -- seq_num
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"00");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"00");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"00");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"02");

           -- clpr
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"00"); -- flag
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"18"); -- protocol

           -- dummy
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"00");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"00");

           -- src_addr
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"00");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"01");

           -- dest_addr
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"00");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"02");

           -- payload

           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"48");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"65");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"6C");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"6C");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"6F");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"20");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"57");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"6F");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"72");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"6C");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"64");
           clock_cycle_with_last_data(slave_i_clk, S_AXIS_T_LAST, S_AXIS_T_DATA , X"21");

           wait for 5 ns;
           wait for 5 ns;
           i_src_port <= "00010";
           wait for 15 ns;

            -- new transmission
            -- envio de SA=2 para DA=1

           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"00");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"07");

           -- checksum
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"10");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"86");

           -- seq_num
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"00");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"00");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"00");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"06");

           -- clpr
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"00"); -- flag
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"18"); -- protocol

           -- dummy
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"00");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"00");

           -- src_addr
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"00");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"02");

           -- dest_addr
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"00");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"01");

           -- payload

           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"21");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"64");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"6C");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"72");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"6F");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"57");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"20");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"6F");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"6C");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"6C");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA , X"65");
           clock_cycle_with_last_data(slave_i_clk, S_AXIS_T_LAST, S_AXIS_T_DATA , X"48");

           wait for 5 ns;
           wait for 5 ns;
           i_src_port <= "00001";
           wait for 15 ns;

            -- new transmission
            -- desconexão de SA=1

           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA, X"00");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA, X"04");

           -- checksum
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA, X"FE");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA, X"DF");

           -- seq_num
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA, X"00");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA, X"00");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA, X"00");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA, X"03");

           -- clpr
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA, X"01"); -- flag
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA, X"18"); -- protocol

           -- dummy
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA, X"00");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA, X"00");

           -- src_addr
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA, X"00");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA, X"01");

           -- dest_addr
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA, X"00");
           clock_cycle_with_last_data(slave_i_clk, S_AXIS_T_LAST, S_AXIS_T_DATA, X"00");

           wait for 5 ns;
           wait for 5 ns;
           i_src_port <= "00010";
           wait for 15 ns;

            -- new transmission
            -- desconexão de SA=2

           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA, X"00");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA, X"04");

           -- checksum
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA, X"FE");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA, X"DA");

           -- seq_num
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA, X"00");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA, X"00");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA, X"00");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA, X"07");

           -- clpr
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA, X"01"); -- flag
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA, X"18"); -- protocol

           -- dummy
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA, X"00");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA, X"00");

           -- src_addr
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA, X"00");
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA, X"02");

           -- dest_addr
           clock_cycle_with_data(slave_i_clk, S_AXIS_T_DATA, X"00");
           clock_cycle_with_last_data(slave_i_clk, S_AXIS_T_LAST, S_AXIS_T_DATA, X"00");

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
