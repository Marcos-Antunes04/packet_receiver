library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_module is
    port(
        -- slave interface ports
        slave_i_clk : in std_logic;
        S_AXIS_T_VALID : in std_logic;
        S_AXIS_T_LAST : in std_logic;
        S_AXIS_T_READY : out std_logic;
        S_AXIS_T_DATA : in std_logic_vector(7 downto 0);
        i_src_port : in std_logic_vector(4 downto 0);

        -- master interface ports
        
        M_AXIS_TREADY : in  std_logic;
        M_AXIS_TVALID : out std_logic;
        M_AXIS_TLAST  : out std_logic;
        M_AXIS_TDATA  : out std_logic_vector(7 downto 0);
        master_o_flags : out std_logic_vector(6 downto 0);

        master_o_dest_port : out std_logic_vector(04 downto 0);
        master_o_dest_addr : out std_logic_vector(15 downto 0)
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

    signal w_port_controller_clock    : std_logic;
    signal w_flag                     : std_logic_vector(07 downto 0);
    signal w_packet_length            : std_logic_vector(15 downto 0);
    signal w_checksum                 : std_logic_vector(15 downto 0);
    signal w_src_addr                 : std_logic_vector(15 downto 0);
    signal w_seq_num                  : std_logic_vector(31 downto 0);
    signal w_dest_addr                : std_logic_vector(15 downto 0);
    signal w_ready                    : std_logic := '1';
    signal o_dest_port                : std_logic_vector(04 downto 0);
    signal o_dest_addr                : std_logic_vector(15 downto 0);
    signal o_calc_checksum            : std_logic_vector(15 downto 0);
    signal w_calc_packet_lenght       : std_logic_vector(15 downto 0);
    signal w_expected_seq_num         : std_logic_vector(31 downto 0);

    component checksum
    port(
        -- input ports
        i_clk, S_AXIS_T_VALID, S_AXIS_T_LAST : in std_logic;
        S_AXIS_T_READY : in std_logic;
        S_AXIS_T_DATA : in std_logic_vector(7 downto 0);
        i_received_checksum : in std_logic_vector(15 downto 0);
        -- output ports
        o_calc_checksum : out std_logic_vector(15 downto 0);        
        o_checksum_error : out std_logic
    );
    end component;

    component packet_length
    port(
        -- input ports
        i_clk, S_AXIS_T_VALID, S_AXIS_T_LAST : in std_logic;
        S_AXIS_T_READY                       : in std_logic;
        i_received_packet_length             : in std_logic_vector(15 downto 0);
        -- output ports            
        o_packet_length_error                : out std_logic;
        o_calc_packet_length                 : out std_logic_vector(15 downto 0)
    );
    end component;

    component header_extractor
    port(
        -- input ports
        i_clk, S_AXIS_T_VALID, S_AXIS_T_LAST : in std_logic;
        S_AXIS_T_READY          : in std_logic;
        S_AXIS_T_DATA           : in std_logic_vector(7 downto 0);
        -- output ports                
        o_packet_length         : out std_logic_vector(15 downto 0) := (others => '0');
        o_flag                  : out std_logic_vector(07 downto 0) := (others => '0');
        o_seq_num               : out std_logic_vector(31 downto 0) := (others => '0');
        o_src_addr              : out std_logic_vector(15 downto 0) := (others => '0');
        o_dest_addr             : out std_logic_vector(15 downto 0) := (others => '0');
        o_checksum              : out std_logic_vector(15 downto 0) := (others => '0');
        o_port_controller_clock : out std_logic := '0'
    );
    end component;

    component port_controller
    port(
        -- input ports
        S_AXIS_T_VALID, S_AXIS_T_LAST : in std_logic;
        S_AXIS_T_READY                : in std_logic;
        i_src_port                    : in std_logic_vector(4 downto 0);
        i_port_clock_controller       : in std_logic;
        i_flag                        : in std_logic_vector(07 downto 0) := (others => '0');
        i_seq_num                     : in std_logic_vector(31 downto 0) := (others => '0');
        i_src_addr                    : in std_logic_vector(15 downto 0) := (others => '0');
        i_dest_addr                   : in std_logic_vector(15 downto 0) := (others => '0');

        -- output ports
        o_dest_port                   : out std_logic_vector(04 downto 0) := (others => '0');
        o_dest_addr                   : out std_logic_vector(15 downto 0) := (others => '0');
        seq_num_error                 : out std_logic := '0';
        dest_addr_error               : out std_logic := '0';
        sync_error                    : out std_logic := '0';
        close_error                   : out std_logic := '0';
        sync_close_error              : out std_logic := '0';
        o_expected_seq_num            : out std_logic_vector(31 downto 0)
    );
    end component;

    component output_controller
    port(
        slave_i_clk                : in  std_logic;
        S_AXIS_T_LAST              : in  std_logic;
        i_flag                     : in  std_logic_vector(06 downto 0);
        i_calc_checksum            : in  std_logic_vector(15 downto 0); -- 2 clock cycles
        i_dest_addr                : in  std_logic_vector(15 downto 0); -- 2 clock cycles
        i_seq_num_expected         : in  std_logic_vector(31 downto 0); -- 4 clock cycles
        i_packet_length_expected   : in  std_logic_vector(15 downto 0); -- 2 clock cycles
        i_dest_port                : in  std_logic_vector(04 downto 0);
        M_AXIS_TREADY             : in  std_logic;
        M_AXIS_TVALID             : out std_logic;
        M_AXIS_TLAST              : out std_logic;
        M_AXIS_TDATA              : out std_logic_vector(07 downto 0);
        master_o_dest_port         : out std_logic_vector(04 downto 0);
        master_o_dest_addr         : out std_logic_vector(15 downto 0);
        master_o_flags             : out std_logic_vector(06 downto 0)
    );
    end component;

begin

    module_checksum: checksum
    port map (
        i_clk               => slave_i_clk,
        S_AXIS_T_READY      => w_ready,
        S_AXIS_T_VALID      => S_AXIS_T_VALID,
        S_AXIS_T_LAST       => S_AXIS_T_LAST,
        i_received_checksum => w_checksum,
        S_AXIS_T_DATA       => S_AXIS_T_DATA,
        o_calc_checksum     => o_calc_checksum,
        o_checksum_error    => checksum_error 
    );

    module_packet_length: packet_length
    port map (
        i_clk                    => slave_i_clk,
        S_AXIS_T_READY           => w_ready,
        S_AXIS_T_VALID           => S_AXIS_T_VALID,
        S_AXIS_T_LAST            => S_AXIS_T_LAST,
        i_received_packet_length => w_packet_length,
        o_packet_length_error    => packet_length_error,
        o_calc_packet_length     => w_calc_packet_lenght
    );

    module_header_extractor: header_extractor
    port map (
        i_clk                   => slave_i_clk,
        S_AXIS_T_READY          => w_ready,
        S_AXIS_T_VALID          => S_AXIS_T_VALID,
        S_AXIS_T_LAST           => S_AXIS_T_LAST,
        S_AXIS_T_DATA           => S_AXIS_T_DATA,
        o_flag                  => w_flag, 
        o_packet_length         => w_packet_length,
        o_seq_num               => w_seq_num, 
        o_src_addr              => w_src_addr, 
        o_dest_addr             => w_dest_addr, 
        o_checksum              => w_checksum,
        o_port_controller_clock => w_port_controller_clock 
    );

    module_port_controller: port_controller
    port map (
        i_port_clock_controller  => w_port_controller_clock,
        S_AXIS_T_READY           => w_ready,
        S_AXIS_T_VALID           => S_AXIS_T_VALID,
        S_AXIS_T_LAST            => S_AXIS_T_LAST,
        i_flag                   => w_flag, 
        i_seq_num                => w_seq_num, 
        i_src_addr               => w_src_addr, 
        i_dest_addr              => w_dest_addr,
        i_src_port               => i_src_port,
        o_dest_addr              => o_dest_addr,
        o_dest_port              => o_dest_port,
        seq_num_error            => seq_num_error,
        dest_addr_error          => dest_addr_not_found,
        sync_error               => sync_error,
        close_error              => close_error,
        sync_close_error         => sync_close_error,
        o_expected_seq_num       => w_expected_seq_num
    );

    module_output_controller: output_controller
    port map (        
            slave_i_clk => slave_i_clk,
            S_AXIS_T_LAST => S_AXIS_T_LAST,
            i_flag => flags,
            i_calc_checksum => o_calc_checksum,
            i_dest_addr => o_dest_addr,
            i_seq_num_expected => w_expected_seq_num,
            i_packet_length_expected => w_calc_packet_lenght,
            i_dest_port => o_dest_port,
            M_AXIS_TREADY => M_AXIS_TREADY,
            M_AXIS_TVALID => M_AXIS_TVALID,
            M_AXIS_TLAST => M_AXIS_TLAST,
            M_AXIS_TDATA => M_AXIS_TDATA,
            master_o_dest_port => master_o_dest_port,
            master_o_dest_addr => master_o_dest_addr,
            master_o_flags => master_o_flags
        );

    S_AXIS_T_READY <= w_ready;

end behavioral;
