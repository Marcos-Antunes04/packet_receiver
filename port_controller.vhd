library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity port_controller is
    port(
        -- input ports
        S_AXIS_T_VALID          : in std_logic;
        i_last           : in std_logic;
        S_AXIS_T_READY          : in std_logic;
        i_src_port              : in std_logic_vector(4 downto 0);
        i_port_clock_controller : in std_logic;
        i_flag                  : in std_logic_vector(07 downto 0) := (others => '0');
        i_seq_num               : in std_logic_vector(31 downto 0) := (others => '0');
        i_src_addr              : in std_logic_vector(15 downto 0) := (others => '0');
        i_dest_addr             : in std_logic_vector(15 downto 0) := (others => '0');
        -- output ports
        o_dest_port             : out std_logic_vector(04 downto 0) := (others => '0');
        o_dest_addr             : out std_logic_vector(15 downto 0) := (others => '0');
        o_seq_num_error         : out std_logic := '0';
        o_dest_addr_error       : out std_logic := '0';
        o_sync_error            : out std_logic := '0';
        o_close_error           : out std_logic := '0';
        o_sync_close_error      : out std_logic := '0';
        o_expected_seq_num      : out std_logic_vector(31 downto 0) := (others => '0')
    );
end port_controller;

architecture behavioral of port_controller is
type t_state_type is (START, SEQ_NUM_CAPTURE, FLAG_CAPTURE, SRC_ADDR_CAPTURE, DEST_ADDR_CAPTURE);
signal state_reg  : t_state_type := START; -- por padrão, o estado começa como START
signal state_next : t_state_type;

signal open_ports_reg         : std_logic_vector(4 downto 0)   := (others => '1');
signal OPEN_PORTS_NEXT        : std_logic_vector(4 downto 0)   := (others => '1'); -- por padrão, todas as portas são inicializadas livres
     
signal src_addr_reg           : std_logic_vector(15 downto 0)  := (others => '0');
signal src_addr_next          : std_logic_vector(15 downto 0)  := (others => '0');

signal SRC_PORT_REG           : std_logic_vector(04 downto 0)  := (others => '0');
signal SRC_PORT_NEXT           : std_logic_vector(04 downto 0) := (others => '0');

signal dest_addr_reg          : std_logic_vector(15 downto 0)  := (others => '0');
signal dest_addr_next         : std_logic_vector(15 downto 0)  := (others => '0');
     
signal dest_port_reg          : std_logic_vector(4 downto 0)   := (others => '0');
signal dest_port_next         : std_logic_vector(4 downto 0)   := (others => '0');
     
signal SEQ_NUM_REG            : std_logic_vector(31 downto 0)  := (others => '0');
signal SEQ_NUM_NEXT           : std_logic_vector(31 downto 0)  := (others => '0');
 
signal expected_seq_num_reg   : std_logic_vector(31 downto 0)  := (others => '0');
signal expected_seq_num_next  : std_logic_vector(31 downto 0)  := (others => '0');

signal flag_reg               : std_logic_vector(7 downto 0)   := (others => '0');
signal flag_next              : std_logic_vector(7 downto 0)   := (others => '0');

-- registradores de memória
signal r_seq_num_reg,  r_seq_num_next  : std_logic_vector(159 downto 0) := (others => '0');
signal r_src_addr_reg, r_src_addr_next : std_logic_vector(79 downto 0) := (others => '0');

-- registradores de sinal de erro
signal seq_num_error_reg, seq_num_error_next       : std_logic := '0';
signal sync_close_error_reg, sync_close_error_next : std_logic := '0';
signal sync_error_reg, sync_error_next             : std_logic := '0';
signal close_error_reg, close_error_next           : std_logic := '0';
signal dest_addr_error_reg, dest_addr_error_next   : std_logic := '0';
begin

    state_machine: process(i_port_clock_controller)
    begin
        if(rising_edge(i_port_clock_controller)) then
            state_reg             <= state_next;
            seq_num_error_reg     <= seq_num_error_next;
            open_ports_reg        <= OPEN_PORTS_NEXT;
            flag_reg              <= flag_next;
            src_addr_reg          <= src_addr_next;
            SRC_PORT_REG          <= SRC_PORT_NEXT;
            dest_addr_reg         <= dest_addr_next;
            SEQ_NUM_REG           <= SEQ_NUM_NEXT;
            dest_port_reg         <= dest_port_next;
            r_src_addr_reg        <= r_src_addr_next;
            r_seq_num_reg         <= r_seq_num_next;
            seq_num_error_reg     <= seq_num_error_next;
            sync_close_error_reg  <= sync_close_error_next;
            sync_error_reg        <= sync_error_next;
            close_error_reg       <= close_error_next;
            expected_seq_num_reg  <= expected_seq_num_next;
        end if;
    end process;

    next_state: process(state_reg, i_last, S_AXIS_T_READY, S_AXIS_T_VALID)
    begin
        -- default value
        state_next <= state_reg;
        case state_reg is
            when START =>
                if(i_last = '1') then
                    state_next <= DEST_ADDR_CAPTURE;
                elsif(S_AXIS_T_READY = '1' and S_AXIS_T_VALID = '1') then
                    state_next <= SEQ_NUM_CAPTURE;
                end if;
            when SEQ_NUM_CAPTURE   =>
                if(i_last = '1') then
                    state_next <= FLAG_CAPTURE;
                elsif(S_AXIS_T_READY = '1' and S_AXIS_T_VALID = '1') then
                    state_next <= FLAG_CAPTURE;
                end if;
            when FLAG_CAPTURE =>
                if(i_last = '1') then
                    state_next <= SRC_ADDR_CAPTURE;
                elsif(S_AXIS_T_READY = '1' and S_AXIS_T_VALID = '1') then
                    state_next <= SRC_ADDR_CAPTURE;
                end if;
            when SRC_ADDR_CAPTURE  =>
                if(i_last = '1') then
                    state_next <= DEST_ADDR_CAPTURE;
                elsif(S_AXIS_T_READY = '1' and S_AXIS_T_VALID = '1') then
                    state_next <= DEST_ADDR_CAPTURE;
                end if;
            when DEST_ADDR_CAPTURE =>
                if(i_last = '1') then
                    state_next <= state_reg;
                else
                    state_next <= SEQ_NUM_CAPTURE;
                end if;
            when others =>
        end case;
    end process;
                  
    datapath: process(state_reg, open_ports_reg, src_addr_reg, dest_addr_reg, SEQ_NUM_REG, flag_reg, r_seq_num_reg, r_src_addr_reg, seq_num_error_reg, sync_close_error_reg, sync_error_reg, close_error_reg, expected_seq_num_reg, SRC_PORT_REG)
    begin
        OPEN_PORTS_NEXT       <= open_ports_reg;
        flag_next             <= flag_reg;
        src_addr_next         <= src_addr_reg;
        dest_addr_next        <= dest_addr_reg;
        SEQ_NUM_NEXT          <= SEQ_NUM_REG;
        dest_port_next        <= dest_port_reg;
        r_seq_num_next        <= r_seq_num_reg;
        r_src_addr_next       <= r_src_addr_reg; 
        seq_num_error_next    <= seq_num_error_reg;
        sync_close_error_next <= sync_close_error_reg;
        sync_error_next       <= sync_error_reg;
        close_error_next      <= close_error_reg;
        dest_addr_error_next  <= dest_addr_error_reg;
        expected_seq_num_next <= expected_seq_num_reg;

        case state_reg is
            -- início do pacote
            when START =>
                dest_port_next         <= (others => '0');
                dest_addr_next         <= (others => '0');
                SEQ_NUM_NEXT           <= (others => '0');
                expected_seq_num_next  <= (others => '0');
                seq_num_error_next     <= '0';
                sync_error_next        <= '0';
                close_error_next       <= '0';
                sync_close_error_next  <= '0';
                dest_addr_error_next   <= '0';

            -- captura do sequence number
            when SEQ_NUM_CAPTURE   =>
                SEQ_NUM_NEXT <= i_seq_num;

            -- captura do flag
            when FLAG_CAPTURE =>
                flag_next <= i_flag;

            -- captura do source address
            when SRC_ADDR_CAPTURE  =>
                src_addr_next <= i_src_addr;
                SRC_PORT_NEXT <= i_src_port;

            -- captura do destination address
            when DEST_ADDR_CAPTURE =>

                dest_addr_next <= i_dest_addr;

                if(flag_reg(7) = '1' and flag_reg(0) = '1') then
                    sync_close_error_next <= '1';
                else
                    sync_close_error_next <= '0';
                end if;

                -- tratamento de mensagem de sincronização
                if((flag_reg(7) = '1') and (flag_reg(0) = '0')) then
                    if(((SRC_PORT_REG and open_ports_reg) = "00000")) then
                        sync_error_next <= '1';
                    else
                        sync_error_next <= '0';
                        OPEN_PORTS_NEXT <= open_ports_reg and (not SRC_PORT_REG);
                        case SRC_PORT_REG is
                            when "00001" => 
                                r_src_addr_next(15 downto 00)  <= src_addr_next;
                                r_seq_num_next(31 downto 00)   <= SEQ_NUM_NEXT; 
                            when "00010" =>  
                                r_src_addr_next(31 downto 16)  <= src_addr_next;
                                r_seq_num_next(63 downto 32)   <= SEQ_NUM_NEXT;
                            when "00100" =>  
                                r_src_addr_next(47 downto 32)  <= src_addr_next;
                                r_seq_num_next(95 downto 64)   <= SEQ_NUM_NEXT;
                            when "01000" =>  
                                r_src_addr_next(63 downto 48)  <= src_addr_next;
                                r_seq_num_next(127 downto 96)  <= SEQ_NUM_NEXT;
                            when "10000" =>  
                                r_src_addr_next(79 downto 64)  <= src_addr_next;
                                r_seq_num_next(159 downto 128) <= SEQ_NUM_NEXT;
                            when others =>
                        end case;
                    end if;

                -- se for mensagem de payload ou fechamento o seq_num será analisado
                elsif((flag_reg(7) = '0') and ((SRC_PORT_REG and open_ports_reg) = "00000")) then
                    case SRC_PORT_REG is
                        when "00001" => 
                            r_seq_num_next(31 downto 00) <= SEQ_NUM_NEXT; 
                            if(not(unsigned(SEQ_NUM_REG) = unsigned(unsigned(r_seq_num_reg(31 downto 00)) + 1))) then
                                seq_num_error_next <= '1';
                                expected_seq_num_next <= std_logic_vector(unsigned(unsigned(r_seq_num_reg(31 downto 00)) + 1));
                            end if;
                        when "00010" => 
                            r_seq_num_next(63 downto 32) <= SEQ_NUM_NEXT; 
                            if(not(unsigned(SEQ_NUM_REG) = unsigned(unsigned(r_seq_num_reg(63 downto 32)) + 1))) then
                                seq_num_error_next <= '1';
                                expected_seq_num_next <= std_logic_vector(unsigned(unsigned(r_seq_num_reg(63 downto 32)) + 1));
                            end if;
                        when "00100" => 
                            r_seq_num_next(95 downto 64) <= SEQ_NUM_NEXT; 
                            if(not(unsigned(SEQ_NUM_REG) = unsigned(unsigned(r_seq_num_reg(95 downto 64)) + 1))) then
                                seq_num_error_next <= '1';
                                expected_seq_num_next <= std_logic_vector(unsigned(unsigned(r_seq_num_reg(95 downto 64)) + 1));
                            end if;
                        when "01000" => 
                            r_seq_num_next(127 downto 96) <= SEQ_NUM_NEXT; 
                            if(not(unsigned(SEQ_NUM_REG) = unsigned(unsigned(r_seq_num_reg(127 downto 96)) + 1))) then
                                seq_num_error_next <= '1';
                                expected_seq_num_next <= std_logic_vector(unsigned(unsigned(r_seq_num_reg(127 downto 96)) + 1));
                            end if;
                        when "10000" => 
                            r_seq_num_next(159 downto 128) <= SEQ_NUM_NEXT; 
                            if(not(unsigned(SEQ_NUM_REG) = unsigned(unsigned(r_seq_num_reg(159 downto 128)) + 1))) then
                                seq_num_error_next <= '1';
                                expected_seq_num_next <= std_logic_vector(unsigned(unsigned(r_seq_num_reg(159 downto 128)) + 1));
                            end if;
                        when others =>
                            seq_num_error_next <= '0';
                    end case;
                   
                end if; 

                -- tratamento de mensagem de fechamento
                if(flag_reg(7) = '0' and flag_reg(0) = '1') then
                    if(not((SRC_PORT_REG and open_ports_reg) = "00000")) then 
                        close_error_next <= '1';
                        OPEN_PORTS_NEXT <= open_ports_reg;
                    else
                        close_error_next <= '0';
                        OPEN_PORTS_NEXT <= open_ports_reg or SRC_PORT_REG;
                    end if;
                end if;
                
                -- caso em que não se trata de mensagem de sincronização ou fechamento
                if(not(flag_reg(7) = '1' or flag_reg(0) = '1') and ((SRC_PORT_REG and open_ports_reg) = "00000")) then
                    -- destination address not found error 
                    if   (i_dest_addr = r_src_addr_reg(15 downto 00) and open_ports_reg(0) = '0') then
                        dest_port_next <= "00001"; 
                    elsif(i_dest_addr = r_src_addr_reg(31 downto 16) and open_ports_reg(1) = '0') then
                        dest_port_next <= "00010"; 
                    elsif(i_dest_addr = r_src_addr_reg(47 downto 32) and open_ports_reg(2) = '0') then
                        dest_port_next <= "00100"; 
                    elsif(i_dest_addr = r_src_addr_reg(63 downto 48) and open_ports_reg(3) = '0') then
                        dest_port_next <= "01000"; 
                    elsif(i_dest_addr = r_src_addr_reg(79 downto 64) and open_ports_reg(4) = '0') then
                        dest_port_next <= "10000"; 
                    else
                        dest_addr_error_next <= '1';
                    end if;
                end if;

                if(i_port_clock_controller = '0') then
                    seq_num_error_next    <= '0';
                    sync_close_error_next <= '0';
                    sync_error_next       <= '0';
                    sync_close_error_next <= '0';
                end if;

            -- eventually idle
            when others =>
        end case;
    end process;

    o_close_error      <= close_error_next;

    o_sync_close_error <= sync_close_error_next;
    
    o_seq_num_error    <= seq_num_error_next;

    o_dest_addr        <= dest_addr_next;

    o_dest_port        <= dest_port_next;

    o_sync_error       <= sync_error_next;

    o_dest_addr_error  <= dest_addr_error_next;

    o_expected_seq_num <= expected_seq_num_next;
end behavioral;
