library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity top_module is
    port(
        -- slave interface ports
        i_clk, i_valid, i_last : in std_logic;
        o_ready : out std_logic;
        i_data : in std_logic_vector(7 downto 0);
        i_src_port : in std_logic_vector(4 downto 0);

        -- master interface ports
        o_valid : out std_logic;
        i_ready : in  std_logic;
        o_dest_port : out std_logic_vector(4 downto 0);
        o_dest_addr : out std_logic_vector(15 downto 0);
        o_calc_checksum : out std_logic_vector(15 downto 0);
        o_flags : out std_logic_vector(6 downto 0)
    );
end top_module;

architecture behavioral of top_module is
    alias payload_length_error : std_logic is o_flags(0);
    alias checksum_error       : std_logic is o_flags(1);
    alias seq_num_error        : std_logic is o_flags(2);
    alias dest_addr_not_found  : std_logic is o_flags(3);
    alias sync_error           : std_logic is o_flags(4);
    alias close_error          : std_logic is o_flags(5);
    alias sync_close_error     : std_logic is o_flags(6);

begin




end behavioral;
