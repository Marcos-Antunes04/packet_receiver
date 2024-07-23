library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity port_controller is
    port(
        -- input ports
        i_ready, i_valid, i_last : in std_logic;
        i_counter : in std_logic_vector(15 downto 0);
        i_data : in std_logic_vector(7 downto 0);
        i_src_port, i_dest_port: in std_logic_vector(4 downto 0);
        -- output ports
        o_src_addr, o_dest_addr : out std_logic_vector(15 downto 0);
        -- portas de tratamento de erro, por padrão inicializadas com '0'
        seq_num_error : out std_logic   := '0';
        dest_addr_error : out std_logic := '0';
        sync_error : out std_logic      := '0';
        close_error : out std_logic     := '0'
    );
end port_controller;

architecture behavioral of port_controller is
signal open_ports : std_logic_vector(4 downto 0)  := (others => '1'); -- por padrão, todas as portas são inicializadas livres
signal src_addr : std_logic_vector(15 downto 0)   := (others => '0');
signal dest_addr : std_logic_vector(15 downto 0)  := (others => '0');

begin
    process(i_counter, i_ready, i_valid, i_last)
    begin
        if(i_last = '0') then
            if((i_counter = X"0000") or (i_ready = '0') or (i_valid = '0')) then

            end if;
        else

        end if;
    end process;

    o_src_addr <= src_addr;
    o_dest_addr <= dest_addr;
end behavioral;
