library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity port_controller is
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
        o_dest_port             : out std_logic_vector(04 downto 0) := (others => '0');
        o_dest_addr             : out std_logic_vector(15 downto 0) := (others => '0');
        seq_num_error           : out std_logic := '0';
        dest_addr_error         : out std_logic := '0';
        sync_error              : out std_logic := '0';
        close_error             : out std_logic := '0';
        sync_close_error        : out std_logic := '0'
    );
end port_controller;

architecture behavioral of port_controller is
type state_type is (idle,start, seq_num_capture, flag_capture, src_addr_capture, dest_addr_capture);
signal state_reg  : state_type := start; -- por padrão, o estado começa como least significant
signal state_next : state_type;
signal open_ports_reg, open_ports_next : std_logic_vector(4 downto 0)      := (others => '1'); -- por padrão, todas as portas são inicializadas livres
signal src_addr_reg, src_addr_next : std_logic_vector(15 downto 0)         := (others => '0');
signal dest_addr_reg, dest_addr_next : std_logic_vector(15 downto 0)       := (others => '0');
signal dest_port_reg, dest_port_next : std_logic_vector(4 downto 0)        := (others => '0');
signal seq_num_reg, seq_num_next : std_logic_vector(31 downto 0)           := (others => '0');
signal flag_reg, flag_next : std_logic_vector(7 downto 0)                  := (others => '0');
signal mem_seq_num_reg,  mem_seq_num_next : std_logic_vector(159 downto 0) := (others => '0');
signal mem_src_addr_reg, mem_src_addr_next : std_logic_vector(79 downto 0) := (others => '0');
signal seq_num_error_reg, seq_num_error_next : std_logic := '0';
signal estado : std_logic_vector(2 downto 0) := (others => '0');

begin

    -- processo de atualização de estados
    process(i_port_clock_controller, i_last)
    begin
        if(i_valid = '0') then
            state_reg <= idle;
            seq_num_error_reg <= seq_num_error_next;
            open_ports_reg    <= open_ports_next;
            flag_reg          <= flag_next;
            src_addr_reg      <= src_addr_next;
            dest_addr_reg     <= dest_addr_next;
            seq_num_reg       <= seq_num_next;
            dest_port_reg     <= dest_port_next;
            mem_src_addr_reg  <= mem_src_addr_next;
            mem_seq_num_reg   <= mem_seq_num_next;
            seq_num_error_reg <= seq_num_error_reg;
        elsif(rising_edge(i_port_clock_controller)) then
            state_reg         <= state_next;
            seq_num_error_reg <= seq_num_error_next;
            open_ports_reg    <= open_ports_next;
            flag_reg          <= flag_next;
            src_addr_reg      <= src_addr_next;
            dest_addr_reg     <= dest_addr_next;
            seq_num_reg       <= seq_num_next;
            dest_port_reg     <= dest_port_next;
            mem_src_addr_reg  <= mem_src_addr_next;
            mem_seq_num_reg   <= mem_seq_num_next;
            seq_num_error_reg <= seq_num_error_next;
        
        elsif(falling_edge(i_last)) then
            state_reg         <= start;
            open_ports_reg    <= open_ports_next;
            flag_reg          <= (others => '0');
            src_addr_reg      <= (others => '0');
            dest_addr_reg     <= (others => '0');
            seq_num_reg       <= (others => '0');
            dest_port_reg     <= (others => '0');
            mem_src_addr_reg  <= mem_src_addr_next;
            mem_seq_num_reg   <= mem_seq_num_next;
            seq_num_error_reg <= '0';
        end if;
    end process;

    -- lógica combinacional de próximo estado
    state_next <= seq_num_capture   when state_reg = start             else
                  flag_capture      when state_reg = seq_num_capture   else
                  src_addr_capture  when state_reg = flag_capture      else
                  dest_addr_capture when state_reg = src_addr_capture  else
                  dest_addr_capture when state_reg = dest_addr_capture;
                  
    estado <= "000" when state_reg = start            else
              "001" when state_reg = seq_num_capture  else
              "010" when state_reg = flag_capture     else
              "011" when state_reg = src_addr_capture else
              "100" when state_reg = dest_addr_capture;
              

    -- operações de estado
    process(state_reg, open_ports_reg, src_addr_reg, dest_addr_reg, seq_num_reg, flag_reg, mem_seq_num_reg, mem_src_addr_reg,seq_num_error_reg)
    begin
        open_ports_next    <= open_ports_reg;
        flag_next          <= flag_reg;
        src_addr_next      <= src_addr_reg;
        dest_addr_next     <= dest_addr_reg;
        seq_num_next       <= seq_num_reg;
        dest_port_next     <= dest_port_reg;
        mem_seq_num_next   <= mem_seq_num_reg;
        mem_src_addr_next  <= mem_src_addr_reg; 
        seq_num_error_next <= seq_num_error_reg;

        case state_reg is
            -- início do pacote
            when start =>
                o_dest_port         <= (others => '0');
                o_dest_addr         <= (others => '0');
                dest_addr_error     <= '0';
                seq_num_error_reg   <= '0';
                sync_error          <= '0';
                close_error         <= '0';
                sync_close_error    <= '0';

            -- captura do sequence number
            when seq_num_capture   =>
                seq_num_next <= i_seq_num;

            -- captura do flag
            when flag_capture      =>
                flag_next <= i_flag;

            -- captura do source address
            when src_addr_capture  =>
                src_addr_next <= i_src_addr;

            -- captura do destination address
            when dest_addr_capture =>
                dest_addr_next <= i_dest_addr;
                o_dest_addr <= dest_addr_next;
                -- tratamento de mensagem de sincronização
                if(flag_reg(7) = '1' and flag_reg(0) = '0' and ((i_src_port and open_ports_reg) = "00000")) then
                    sync_error <= '1';
                else
                    open_ports_next <= (open_ports_reg and (not i_src_port));

                    case i_src_port is
                        when "00001" => 
                            mem_src_addr_next(15 downto 00)  <= src_addr_next;
                            mem_seq_num_next(31 downto 00)   <= seq_num_next; 
                            open_ports_next <= open_ports_reg(4 downto 1) & '0';
                        when "00010" =>  
                            mem_src_addr_next(31 downto 16)  <= src_addr_next;
                            mem_seq_num_next(63 downto 32)   <= seq_num_next;
                            open_ports_next <= open_ports_reg(4 downto 2) & '0' & open_ports_reg(0);
                        when "00100" =>  
                            mem_src_addr_next(47 downto 32)  <= src_addr_next;
                            mem_seq_num_next(95 downto 64)   <= seq_num_next;
                            open_ports_next <= open_ports_reg(4 downto 3) & '0' & open_ports_reg(1 downto 0);
                        when "01000" =>  
                            mem_src_addr_next(63 downto 48)  <= src_addr_next;
                            mem_seq_num_next(127 downto 96)  <= seq_num_next;
                            open_ports_next <= open_ports_reg(4) & '0' & open_ports_reg(2 downto 0);
                        when "10000" =>  
                            mem_src_addr_next(79 downto 64)  <= src_addr_next;
                            mem_seq_num_next(159 downto 128) <= seq_num_next;
                            open_ports_next <= '0' & open_ports_reg(3 downto 0);
                        when others =>
                    end case;
                end if; 

                -- tratamento de mensagem de fechamento
                if(flag_reg(7) = '0' and flag_reg(0) = '1' and not ((i_src_port and open_ports_reg) = "00000")) then
                    if(not ((i_src_port and open_ports_reg) = "00000")) then
                        close_error <= '1';
                    else
                        open_ports_next <= open_ports_reg or i_src_port;
                    end if;
                end if;

                -- caso em que não se trata de mensagem de sincronização ou fechamento
                if(not(flag_reg(7) = '1' or flag_reg(0) = '1') and ((i_src_port and open_ports_reg) = "00000")) then
                    case i_src_port is
                        when "00001" => 
                            mem_seq_num_next(31 downto 00) <= seq_num_next; 
                            if(not(unsigned(seq_num_reg) = unsigned(unsigned(mem_seq_num_reg(31 downto 00)) + 1))) then
                                seq_num_error_next <= '1';
                            end if;
                        when "00010" => 
                            mem_seq_num_next(63 downto 32) <= seq_num_next; 
                            if(not(unsigned(seq_num_reg) = unsigned(unsigned(mem_seq_num_reg(63 downto 32)) + 1))) then
                                seq_num_error_next <= '1';
                            end if;
                        when "00100" => 
                            mem_seq_num_next(95 downto 64) <= seq_num_next; 
                            if(not(unsigned(seq_num_reg) = unsigned(unsigned(mem_seq_num_reg(95 downto 64)) + 1))) then
                                seq_num_error_next <= '1';
                            end if;
                        when "01000" => 
                            mem_seq_num_next(127 downto 96) <= seq_num_next; 
                            if(not(unsigned(seq_num_reg) = unsigned(unsigned(mem_seq_num_reg(127 downto 96)) + 1))) then
                                seq_num_error_next <= '1';
                            end if;
                        when "10000" => 
                            mem_seq_num_next(159 downto 128) <= seq_num_next; 
                            if(not(unsigned(seq_num_reg) = unsigned(unsigned(mem_seq_num_reg(159 downto 128)) + 1))) then
                                seq_num_error_next <= '1';
                            end if;
                        when others =>
                            seq_num_error_next <= '0';
                    end case;

                    -- destination address not found error 
                    if(dest_addr_reg = mem_src_addr_reg(15 downto 00)) then 
                    elsif(dest_addr_reg = mem_src_addr_reg(15 downto 00)) then
                    elsif(dest_addr_reg = mem_src_addr_reg(31 downto 16)) then
                    elsif(dest_addr_reg = mem_src_addr_reg(47 downto 32)) then
                    elsif(dest_addr_reg = mem_src_addr_reg(63 downto 48)) then
                    elsif(dest_addr_reg = mem_src_addr_reg(79 downto 64)) then
                    else
                        dest_addr_error <= '1';
                    end if;
                end if;

            -- outros estados => idle (não faz nada)
            when others =>
        end case;
    end process;

    
    sync_close_error <= '1' when (flag_reg(7) = '1' and flag_reg(0) = '1') else
                        '0';
    seq_num_error <= seq_num_error_next;
end behavioral;
