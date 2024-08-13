library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity port_controller is
    port(
        -- input ports
        S_AXIS_T_VALID          : in std_logic;
        S_AXIS_T_LAST           : in std_logic;
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
        seq_num_error           : out std_logic := '0';
        dest_addr_error         : out std_logic := '0';
        sync_error              : out std_logic := '0';
        close_error             : out std_logic := '0';
        sync_close_error        : out std_logic := '0';
        o_expected_seq_num      : out std_logic_vector(31 downto 0) := (others => '0')
    );
end port_controller;

architecture behavioral of port_controller is
type state_type is (START, SEQ_NUM_CAPTURE, FLAG_CAPTURE, SRC_ADDR_CAPTURE, DEST_ADDR_CAPTURE);
signal r_STATE_REG  : state_type := START; -- por padrão, o estado começa como START
signal r_STATE_NEXT : state_type;

signal OPEN_PORTS_REG         : std_logic_vector(4 downto 0)   := (others => '1');
signal OPEN_PORTS_NEXT        : std_logic_vector(4 downto 0)   := (others => '1'); -- por padrão, todas as portas são inicializadas livres
     
signal SRC_ADDR_REG           : std_logic_vector(15 downto 0)  := (others => '0');
signal SRC_ADDR_NEXT          : std_logic_vector(15 downto 0)  := (others => '0');
     
signal DEST_ADDR_REG          : std_logic_vector(15 downto 0)  := (others => '0');
signal DEST_ADDR_NEXT         : std_logic_vector(15 downto 0)  := (others => '0');
     
signal DEST_PORT_REG          : std_logic_vector(4 downto 0)   := (others => '0');
signal DEST_PORT_NEXT         : std_logic_vector(4 downto 0)   := (others => '0');
     
signal SEQ_NUM_REG            : std_logic_vector(31 downto 0)  := (others => '0');
signal SEQ_NUM_NEXT           : std_logic_vector(31 downto 0)  := (others => '0');
 
signal EXPECTED_SEQ_NUM_REG   : std_logic_vector(31 downto 0)  := (others => '0');
signal EXPECTED_SEQ_NUM_NEXT  : std_logic_vector(31 downto 0)  := (others => '0');

signal FLAG_REG        : std_logic_vector(7 downto 0)   := (others => '0');
signal FLAG_NEXT       : std_logic_vector(7 downto 0)   := (others => '0');

-- registradores de memória
signal r_SEQ_NUM_REG,  r_SEQ_NUM_NEXT : std_logic_vector(159 downto 0) := (others => '0');
signal r_SRC_ADDR_REG, r_SRC_ADDR_NEXT : std_logic_vector(79 downto 0) := (others => '0');

-- registradores de sinal de erro
signal SEQ_NUM_ERROR_REG, SEQ_NUM_ERROR_NEXT : std_logic := '0';
signal SYNC_CLOSE_ERROR_REG, sync_CLOSE_ERROR_NEXT : std_logic := '0';
signal SYNC_ERROR_REG, SYNC_ERROR_NEXT : std_logic := '0';
signal CLOSE_ERROR_REG, CLOSE_ERROR_NEXT : std_logic := '0';
signal DEST_ADDR_ERROR_REG, DEST_ADDR_ERROR_NEXT : std_logic := '0';
begin

    -- processo de atualização de estados
    process(i_port_clock_controller)
    begin
        if(rising_edge(i_port_clock_controller)) then
            r_STATE_REG           <= r_STATE_NEXT;
            SEQ_NUM_ERROR_REG     <= SEQ_NUM_ERROR_NEXT;
            OPEN_PORTS_REG        <= OPEN_PORTS_NEXT;
            FLAG_REG              <= FLAG_NEXT;
            SRC_ADDR_REG          <= SRC_ADDR_NEXT;
            DEST_ADDR_REG         <= DEST_ADDR_NEXT;
            SEQ_NUM_REG           <= SEQ_NUM_NEXT;
            DEST_PORT_REG         <= DEST_PORT_NEXT;
            r_SRC_ADDR_REG        <= r_SRC_ADDR_NEXT;
            r_SEQ_NUM_REG         <= r_SEQ_NUM_NEXT;
            SEQ_NUM_ERROR_REG     <= SEQ_NUM_ERROR_NEXT;
            SYNC_CLOSE_ERROR_REG  <= sync_CLOSE_ERROR_NEXT;
            SYNC_ERROR_REG        <= SYNC_ERROR_NEXT;
            SYNC_CLOSE_ERROR_REG  <= sync_CLOSE_ERROR_NEXT;
            EXPECTED_SEQ_NUM_REG  <= EXPECTED_SEQ_NUM_NEXT;
        end if;
    end process;

    process(r_STATE_REG, S_AXIS_T_LAST, S_AXIS_T_READY, S_AXIS_T_VALID)
    begin
        -- default value
        r_STATE_NEXT <= r_STATE_REG;
        case r_STATE_REG is
            when START =>
                if(S_AXIS_T_LAST = '1') then
                    r_STATE_NEXT <= DEST_ADDR_CAPTURE;
                elsif(S_AXIS_T_READY = '1' and S_AXIS_T_VALID = '1') then
                    r_STATE_NEXT <= SEQ_NUM_CAPTURE;
                end if;
            when SEQ_NUM_CAPTURE   =>
                if(S_AXIS_T_LAST = '1') then
                    r_STATE_NEXT <= FLAG_CAPTURE;
                elsif(S_AXIS_T_READY = '1' and S_AXIS_T_VALID = '1') then
                    r_STATE_NEXT <= FLAG_CAPTURE;
                end if;
            when FLAG_CAPTURE =>
                if(S_AXIS_T_LAST = '1') then
                    r_STATE_NEXT <= SRC_ADDR_CAPTURE;
                elsif(S_AXIS_T_READY = '1' and S_AXIS_T_VALID = '1') then
                    r_STATE_NEXT <= SRC_ADDR_CAPTURE;
                end if;
            when SRC_ADDR_CAPTURE  =>
                if(S_AXIS_T_LAST = '1') then
                    r_STATE_NEXT <= DEST_ADDR_CAPTURE;
                elsif(S_AXIS_T_READY = '1' and S_AXIS_T_VALID = '1') then
                    r_STATE_NEXT <= DEST_ADDR_CAPTURE;
                end if;
            when DEST_ADDR_CAPTURE =>
                if(S_AXIS_T_LAST = '1') then
                    r_STATE_NEXT <= r_STATE_REG;
                else
                    r_STATE_NEXT <= SEQ_NUM_CAPTURE;
                end if;
            when others =>
        end case;
    end process;
                  
    -- operações de estado
    process(r_STATE_REG, OPEN_PORTS_REG, SRC_ADDR_REG, DEST_ADDR_REG, SEQ_NUM_REG, FLAG_REG, r_SEQ_NUM_REG, r_SRC_ADDR_REG, SEQ_NUM_ERROR_REG, SYNC_CLOSE_ERROR_REG, SYNC_ERROR_REG, CLOSE_ERROR_REG, EXPECTED_SEQ_NUM_REG)
    begin
        OPEN_PORTS_NEXT       <= OPEN_PORTS_REG;
        FLAG_NEXT             <= FLAG_REG;
        SRC_ADDR_NEXT         <= SRC_ADDR_REG;
        DEST_ADDR_NEXT        <= DEST_ADDR_REG;
        SEQ_NUM_NEXT          <= SEQ_NUM_REG;
        DEST_PORT_NEXT        <= DEST_PORT_REG;
        r_SEQ_NUM_NEXT        <= r_SEQ_NUM_REG;
        r_SRC_ADDR_NEXT       <= r_SRC_ADDR_REG; 
        SEQ_NUM_ERROR_NEXT    <= SEQ_NUM_ERROR_REG;
        sync_CLOSE_ERROR_NEXT <= SYNC_CLOSE_ERROR_REG;
        SYNC_ERROR_NEXT       <= SYNC_ERROR_REG;
        CLOSE_ERROR_NEXT      <= CLOSE_ERROR_REG;
        DEST_ADDR_ERROR_NEXT  <= DEST_ADDR_ERROR_REG;
        EXPECTED_SEQ_NUM_NEXT <= EXPECTED_SEQ_NUM_REG;

        case r_STATE_REG is
            -- início do pacote
            when START =>
                DEST_PORT_NEXT         <= (others => '0');
                DEST_ADDR_NEXT         <= (others => '0');
                SEQ_NUM_NEXT           <= (others => '0');
                EXPECTED_SEQ_NUM_NEXT  <= (others => '0');
                SEQ_NUM_ERROR_NEXT     <= '0';
                SYNC_ERROR_NEXT        <= '0';
                CLOSE_ERROR_NEXT       <= '0';
                sync_CLOSE_ERROR_NEXT  <= '0';
                DEST_ADDR_ERROR_NEXT   <= '0';

            -- captura do sequence number
            when SEQ_NUM_CAPTURE   =>
                SEQ_NUM_NEXT <= i_seq_num;

            -- captura do flag
            when FLAG_CAPTURE =>
                FLAG_NEXT <= i_flag;

            -- captura do source address
            when SRC_ADDR_CAPTURE  =>
                SRC_ADDR_NEXT <= i_src_addr;

            -- captura do destination address
            when DEST_ADDR_CAPTURE =>

                DEST_ADDR_NEXT <= i_dest_addr;

                if(FLAG_REG(7) = '1' and FLAG_REG(0) = '1') then
                    sync_CLOSE_ERROR_NEXT <= '1';
                else
                    sync_CLOSE_ERROR_NEXT <= '0';
                end if;

                -- tratamento de mensagem de sincronização
                if((FLAG_REG(7) = '1') and (FLAG_REG(0) = '0')) then
                    if(((i_src_port and OPEN_PORTS_REG) = "00000")) then
                        SYNC_ERROR_NEXT <= '1';
                    else
                        SYNC_ERROR_NEXT <= '0';
                        OPEN_PORTS_NEXT <= OPEN_PORTS_REG and (not i_src_port);
                        case i_src_port is
                            when "00001" => 
                                r_SRC_ADDR_NEXT(15 downto 00)  <= SRC_ADDR_NEXT;
                                r_SEQ_NUM_NEXT(31 downto 00)   <= SEQ_NUM_NEXT; 
                            when "00010" =>  
                                r_SRC_ADDR_NEXT(31 downto 16)  <= SRC_ADDR_NEXT;
                                r_SEQ_NUM_NEXT(63 downto 32)   <= SEQ_NUM_NEXT;
                            when "00100" =>  
                                r_SRC_ADDR_NEXT(47 downto 32)  <= SRC_ADDR_NEXT;
                                r_SEQ_NUM_NEXT(95 downto 64)   <= SEQ_NUM_NEXT;
                            when "01000" =>  
                                r_SRC_ADDR_NEXT(63 downto 48)  <= SRC_ADDR_NEXT;
                                r_SEQ_NUM_NEXT(127 downto 96)  <= SEQ_NUM_NEXT;
                            when "10000" =>  
                                r_SRC_ADDR_NEXT(79 downto 64)  <= SRC_ADDR_NEXT;
                                r_SEQ_NUM_NEXT(159 downto 128) <= SEQ_NUM_NEXT;
                            when others =>
                        end case;
                    end if;

                -- se for mensagem de payload ou fechamento o seq_num será analisado
                elsif((FLAG_REG(7) = '0') and ((i_src_port and OPEN_PORTS_REG) = "00000")) then
                    case i_src_port is
                        when "00001" => 
                            r_SEQ_NUM_NEXT(31 downto 00) <= SEQ_NUM_NEXT; 
                            if(not(unsigned(SEQ_NUM_REG) = unsigned(unsigned(r_SEQ_NUM_REG(31 downto 00)) + 1))) then
                                SEQ_NUM_ERROR_NEXT <= '1';
                                EXPECTED_SEQ_NUM_NEXT <= std_logic_vector(unsigned(unsigned(r_SEQ_NUM_REG(31 downto 00)) + 1));
                            end if;
                        when "00010" => 
                            r_SEQ_NUM_NEXT(63 downto 32) <= SEQ_NUM_NEXT; 
                            if(not(unsigned(SEQ_NUM_REG) = unsigned(unsigned(r_SEQ_NUM_REG(63 downto 32)) + 1))) then
                                SEQ_NUM_ERROR_NEXT <= '1';
                                EXPECTED_SEQ_NUM_NEXT <= std_logic_vector(unsigned(unsigned(r_SEQ_NUM_REG(63 downto 32)) + 1));
                            end if;
                        when "00100" => 
                            r_SEQ_NUM_NEXT(95 downto 64) <= SEQ_NUM_NEXT; 
                            if(not(unsigned(SEQ_NUM_REG) = unsigned(unsigned(r_SEQ_NUM_REG(95 downto 64)) + 1))) then
                                SEQ_NUM_ERROR_NEXT <= '1';
                                EXPECTED_SEQ_NUM_NEXT <= std_logic_vector(unsigned(unsigned(r_SEQ_NUM_REG(95 downto 64)) + 1));
                            end if;
                        when "01000" => 
                            r_SEQ_NUM_NEXT(127 downto 96) <= SEQ_NUM_NEXT; 
                            if(not(unsigned(SEQ_NUM_REG) = unsigned(unsigned(r_SEQ_NUM_REG(127 downto 96)) + 1))) then
                                SEQ_NUM_ERROR_NEXT <= '1';
                                EXPECTED_SEQ_NUM_NEXT <= std_logic_vector(unsigned(unsigned(r_SEQ_NUM_REG(127 downto 96)) + 1));
                            end if;
                        when "10000" => 
                            r_SEQ_NUM_NEXT(159 downto 128) <= SEQ_NUM_NEXT; 
                            if(not(unsigned(SEQ_NUM_REG) = unsigned(unsigned(r_SEQ_NUM_REG(159 downto 128)) + 1))) then
                                SEQ_NUM_ERROR_NEXT <= '1';
                                EXPECTED_SEQ_NUM_NEXT <= std_logic_vector(unsigned(unsigned(r_SEQ_NUM_REG(159 downto 128)) + 1));
                            end if;
                        when others =>
                            SEQ_NUM_ERROR_NEXT <= '0';
                    end case;
                   
                end if; 

                -- tratamento de mensagem de fechamento
                if(FLAG_REG(7) = '0' and FLAG_REG(0) = '1') then
                    if(not((i_src_port and OPEN_PORTS_REG) = "00000")) then 
                        CLOSE_ERROR_NEXT <= '1';
                        OPEN_PORTS_NEXT <= OPEN_PORTS_REG;
                    else
                        CLOSE_ERROR_NEXT <= '0';
                        OPEN_PORTS_NEXT <= OPEN_PORTS_REG or i_src_port;
                    end if;
                end if;
                
                -- caso em que não se trata de mensagem de sincronização ou fechamento
                if(not(FLAG_REG(7) = '1' or FLAG_REG(0) = '1') and ((i_src_port and OPEN_PORTS_REG) = "00000")) then
                    -- destination address not found error 
                    if   (i_dest_addr = r_SRC_ADDR_REG(15 downto 00) and OPEN_PORTS_REG(0) = '0') then
                        DEST_PORT_NEXT <= "00001"; 
                    elsif(i_dest_addr = r_SRC_ADDR_REG(31 downto 16) and OPEN_PORTS_REG(1) = '0') then
                        DEST_PORT_NEXT <= "00010"; 
                    elsif(i_dest_addr = r_SRC_ADDR_REG(47 downto 32) and OPEN_PORTS_REG(2) = '0') then
                        DEST_PORT_NEXT <= "00100"; 
                    elsif(i_dest_addr = r_SRC_ADDR_REG(63 downto 48) and OPEN_PORTS_REG(3) = '0') then
                        DEST_PORT_NEXT <= "01000"; 
                    elsif(i_dest_addr = r_SRC_ADDR_REG(79 downto 64) and OPEN_PORTS_REG(4) = '0') then
                        DEST_PORT_NEXT <= "10000"; 
                    else
                        DEST_ADDR_ERROR_NEXT <= '1';
                    end if;
                end if;

                if(i_port_clock_controller = '0') then
                    SEQ_NUM_ERROR_NEXT    <= '0';
                    SYNC_CLOSE_ERROR_NEXT <= '0';
                    SYNC_ERROR_NEXT       <= '0';
                    SYNC_CLOSE_ERROR_NEXT <= '0';
                end if;

            -- eventually idle
            when others =>
        end case;
    end process;

    close_error <= CLOSE_ERROR_NEXT;

    sync_close_error <= sync_CLOSE_ERROR_NEXT;
    
    seq_num_error <= SEQ_NUM_ERROR_NEXT;

    o_dest_addr <= DEST_ADDR_NEXT;

    o_dest_port <= DEST_PORT_NEXT;

    sync_error <= SYNC_ERROR_NEXT;

    dest_addr_error <= DEST_ADDR_ERROR_NEXT;

    o_expected_seq_num <= EXPECTED_SEQ_NUM_NEXT;
end behavioral;
