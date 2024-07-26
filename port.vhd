library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity port_controller is
    port(
        -- input ports
        i_ready, i_last : in std_logic;
        o_valid : out std_logic;
        i_counter : in std_logic_vector(15 downto 0);
        i_data : in std_logic_vector(7 downto 0);
        i_src_port: in std_logic_vector(4 downto 0);
        i_port_clock_controller : in std_logic;
        -- output ports
        seq_num_error : out std_logic    := '0';
        dest_addr_error : out std_logic  := '0';
        sync_error : out std_logic       := '0';
        close_error : out std_logic      := '0';
        sync_close_error : out std_logic := '0'
    );
end port_controller;

architecture behavioral of port_controller is
type state_type is (idle,start, seq_num_capture, flag_capture, src_addr_capture, dest_addr_capture);
signal state_reg  : state_type := start; -- por padrão o estado começa como least significant
signal state_next : state_type;
signal open_ports_reg, open_ports_next : std_logic_vector(4 downto 0) := (others => '1'); -- por padrão, todas as portas são inicializadas livres
signal src_addr_reg, src_addr_next : std_logic_vector(15 downto 0)    := (others => '0');
signal dest_addr_reg, dest_addr_next : std_logic_vector(15 downto 0)  := (others => '0');
signal received_seq_num_reg, received_seq_num_next : std_logic_vector(31 downto 0); := (others => '0');
signal flag_reg, flag_next : std_logic_vector(7 downto 0);
signal state_reg, state_next : std_logic_vector(1 downto 0)  := (others => '0'); -- sinal state é responsável por determinar se ocorrerá sincronização, fechamento ou apenas transmissão de pacote
type port_addr is array(4 downto 0) of std_logic_vector(15 downto 0); -- um array de endereços. cada endereço associado a uma porta
type seq_num is array(4 downto 0) of std_logic_vector(31 downto 0);   -- um array de seq_nums. cada seq_num associado a uma porta

begin

    -- processo de atualização de estados
    process(i_port_clock_controller, i_last)
    begin
        if(i_ready = '0') then
            state_reg <= idle;
        elsif(rising_edge(i_port_clock_controller)) then
            state_reg <= state_next;
        elsif(falling_edge(i_port_clock_controller)) then
            state_reg <= start;
        end if;
    end process;
    
    state_next <= seq_num_capture   when state_reg = start             else
                  flag_capture      when state_reg = seq_num_capture   else
                  src_addr_capture  when state_reg = flag_capture      else
                  dest_addr_capture when state_reg = src_addr_capture  else
                  dest_addr_capture when state_reg = dest_addr_capture;
                  
    o_src_addr  <= src_addr;
    o_dest_addr <= dest_addr;

end behavioral;
