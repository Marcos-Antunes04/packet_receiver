library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_module is
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
end top_module;

architecture behavioral of top_module is
    signal flags                      : std_logic_vector(6 downto 0);
    alias packet_length_error         : std_logic is flags(0);
    alias checksum_error              : std_logic is flags(1);
    alias seq_num_error               : std_logic is flags(2);
    alias dest_addr_not_found         : std_logic is flags(3);
    alias sync_error                  : std_logic is flags(4);
    alias close_error                 : std_logic is flags(5);
    alias sync_close_error            : std_logic is flags(6);

    signal link_port_controller_clock : std_logic;
    signal link_flag                  : std_logic_vector(07 downto 0);
    signal link_packet_length         : std_logic_vector(15 downto 0);
    signal link_checksum              : std_logic_vector(15 downto 0);
    signal link_src_addr              : std_logic_vector(15 downto 0);
    signal link_seq_num               : std_logic_vector(31 downto 0);
    signal link_dest_addr             : std_logic_vector(15 downto 0);
    signal o_dest_port                : std_logic_vector(04 downto 0);
    signal o_dest_addr                : std_logic_vector(15 downto 0);
    signal o_calc_checksum            : std_logic_vector(15 downto 0);
       
    signal w_ready                    : std_logic := '1';

    component checksum
    port(
        -- input ports
        i_clk, i_valid, i_last : in std_logic;
        i_ready : in std_logic;
        i_data : in std_logic_vector(7 downto 0);
        i_received_checksum : in std_logic_vector(15 downto 0);
        -- output ports
        o_calc_checksum : out std_logic_vector(15 downto 0);        
        o_checksum_error : out std_logic
    );
    end component;

    component packet_length
    port(
        -- input ports
        i_clk, i_valid, i_last : in std_logic;
        o_ready : out std_logic;
        received_packet_length : in std_logic_vector(15 downto 0);
        -- output ports
        o_packet_length_error : out std_logic
    );
    end component;

    component header_extractor
    port(
        -- input ports
        i_clk, i_valid, i_last : in std_logic;
        i_ready: in std_logic;
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

    component port_controller
    port(
        -- input ports
        i_valid, i_last         : in std_logic;
        o_ready                 : out std_logic;
        i_src_port              : in std_logic_vector(4 downto 0);
        i_port_clock_controller : in std_logic;
        i_flag                  : in std_logic_vector(07 downto 0) := (others => '0');
        i_seq_num               : in std_logic_vector(31 downto 0) := (others => '0');
        i_src_addr              : in std_logic_vector(15 downto 0) := (others => '0');
        i_dest_addr             : in std_logic_vector(15 downto 0) := (others => '0');

        -- output ports
        o_dest_port      : out std_logic_vector(04 downto 0) := (others => '0');
        o_dest_addr      : out std_logic_vector(15 downto 0) := (others => '0');
        seq_num_error    : out std_logic := '0';
        dest_addr_error  : out std_logic := '0';
        sync_error       : out std_logic := '0';
        close_error      : out std_logic := '0';
        sync_close_error : out std_logic := '0'
    );
    end component;

begin

    module_checksum: checksum
    port map (
        i_clk               => slave_i_clk,
        i_ready             => w_ready,
        i_valid             => slave_i_valid,
        i_last              => slave_i_last,
        i_received_checksum => link_checksum,
        i_data              => slave_i_data,
        o_calc_checksum     => o_calc_checksum,
        o_checksum_error    => checksum_error 
    );

    module_packet_length: packet_length
    port map (
        i_clk                  => slave_i_clk,
        o_ready                => slave_o_ready,
        i_valid                => slave_i_valid,
        i_last                 => slave_i_last,
        received_packet_length => link_packet_length,
        o_packet_length_error  => packet_length_error 
    );

    module_header_extractor: header_extractor
    port map (
        i_clk                   => slave_i_clk,
        i_ready                 => w_ready,
        i_valid                 => slave_i_valid,
        i_last                  => slave_i_last,
        i_data                  => slave_i_data,
        o_flag                  => link_flag, 
        o_packet_length         => link_packet_length,
        o_seq_num               => link_seq_num, 
        o_src_addr              => link_src_addr, 
        o_dest_addr             => link_dest_addr, 
        o_checksum              => link_checksum,
        o_port_controller_clock => link_port_controller_clock 
    );

    module_port_controller: port_controller
    port map (
        i_port_clock_controller  => link_port_controller_clock,
        o_ready                  => slave_o_ready,
        i_valid                  => slave_i_valid,
        i_last                   => slave_i_last,
        i_flag                   => link_flag, 
        i_seq_num                => link_seq_num, 
        i_src_addr               => link_src_addr, 
        i_dest_addr              => link_dest_addr,
        i_src_port               => i_src_port,
        o_dest_addr              => o_dest_addr,
        o_dest_port              => o_dest_port,
        seq_num_error            => seq_num_error,
        dest_addr_error          => dest_addr_not_found,
        sync_error               => sync_error,
        close_error              => close_error,
        sync_close_error         => sync_close_error 
    );

    slave_o_ready <= w_ready;

end behavioral;
