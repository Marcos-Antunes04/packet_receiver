library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity port_controller is
    port(
        -- input ports
        i_ready, i_last         : in std_logic;
        o_valid                 : out std_logic;
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
end port_controller;

architecture behavioral of port_controller is
type state_type is (idle,start, seq_num_capture, flag_capture, src_addr_capture, dest_addr_capture, finished);
signal state_reg  : state_type := start; -- por padrão o estado começa como least significant
signal state_next : state_type;
signal open_ports_reg, open_ports_next : std_logic_vector(4 downto 0) := (others => '1'); -- por padrão, todas as portas são inicializadas livres
signal src_addr_reg, src_addr_next : std_logic_vector(15 downto 0)    := (others => '0');
signal dest_addr_reg, dest_addr_next : std_logic_vector(15 downto 0)  := (others => '0');
signal dest_port_reg, dest_port_next : std_logic_vector(4 downto 0)   := (others => '0');
signal seq_num_reg, seq_num_next : std_logic_vector(31 downto 0) := (others => '0');
signal flag_reg, flag_next : std_logic_vector(7 downto 0);
type port_addr is array(4 downto 0) of std_logic_vector(15 downto 0); -- um array de endereços. cada endereço associado a uma porta
type seq_num is array(4 downto 0) of std_logic_vector(31 downto 0);   -- um array de seq_nums. cada seq_num associado a uma porta

begin

    -- processo de atualização de estados
    process(i_port_clock_controller, i_last)
    begin
        if(i_ready = '0') then
            state_reg <= idle;
            open_ports_reg <= open_ports_reg;
            flag_reg       <= flag_reg;
            src_addr_reg   <= src_addr_reg;
            dest_addr_reg  <= dest_addr_reg;
            seq_num_reg    <= seq_num_reg;
            dest_port_reg  <= dest_port_reg;
        elsif(rising_edge(i_port_clock_controller)) then
            state_reg      <= state_next;
            open_ports_reg <= open_ports_next;
            flag_reg       <= flag_next;
            src_addr_reg   <= src_addr_next;
            dest_addr_reg  <= dest_addr_next;
            seq_num_reg    <= seq_num_next;
            dest_port_reg  <= dest_port_next;
        elsif(falling_edge(i_port_clock_controller)) then
            state_reg <= start;
            open_ports_reg <= (others => '0');
            flag_reg       <= (others => '0');
            src_addr_reg   <= (others => '0');
            dest_addr_reg  <= (others => '0');
            seq_num_reg    <= (others => '0');
            dest_port_reg  <= (others => '0');
        end if;
    end process;

    -- lógica combinacional de próximo estado
    state_next <= seq_num_capture   when state_reg = start             else
                  flag_capture      when state_reg = seq_num_capture   else
                  src_addr_capture  when state_reg = flag_capture      else
                  dest_addr_capture when state_reg = src_addr_capture  else
                  finished          when state_reg = dest_addr_capture else
                  finished          when state_reg = finished;

    -- operações de estado
    process(state_reg, open_ports_reg, src_addr_reg, dest_addr_reg, seq_num_reg, flag_reg)
    begin
            state_next      <= state_reg; 
            open_ports_next <= open_ports_reg;
            flag_next       <= flag_reg;
            src_addr_next   <= src_addr_reg;
            dest_addr_next  <= dest_addr_reg;
            seq_num_next    <= seq_num_reg;
            dest_port_next  <= dest_port_reg;

        case state_reg is
            when start =>
                o_dest_port      <= (others => '0');
                o_dest_addr      <= (others => '0');
                seq_num_error    <= '0';
                dest_addr_error  <= '0';
                sync_error       <= '0';
                close_error      <= '0';
                sync_close_error <= '0';
            when seq_num_capture   =>
                seq_num_next <= i_seq_num;
            when flag_capture      =>
                flag_next <= i_flag;
                if(flag_reg(7) = '1' and flag_reg(0) = '0' and ((i_src_port and open_ports_reg) = "00000")) then
                    sync_error <= '1';
                else
                    open_ports_next <= open_ports_reg and not i_src_port;
                    
                end if;

                if(flag_reg(7) = '0' and flag_reg(0) = '1' and not ((i_src_port and open_ports_reg) = "00000")) then
                    close_error <= '1';
                end if;
            when src_addr_capture  =>
                src_addr_next <= i_src_addr;
            when dest_addr_capture =>
                dest_addr_next <= i_dest_addr;
            when finished          =>

            
            when others =>
        end case;
    end process;

    o_dest_addr <= dest_addr_reg;
    
    sync_close_error <= '1' when (flag_reg(7) = '1' and flag_reg(0) = '1') else
                        '0';

end behavioral;
