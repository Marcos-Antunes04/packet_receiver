library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity header_extractor is
    port(
        -- input ports
        i_clk                   : in std_logic;
        S_AXIS_T_VALID          : in std_logic;
        S_AXIS_T_LAST           : in std_logic;
        S_AXIS_T_READY          : in std_logic;
        S_AXIS_T_DATA           : in std_logic_vector(7 downto 0);
        -- output ports 
        o_packet_length         : out std_logic_vector(15 downto 0) := (others => '0');
        o_flag                  : out std_logic_vector(07 downto 0) := (others => '0');
        o_seq_num               : out std_logic_vector(31 downto 0) := (others => '0');
        o_src_addr              : out std_logic_vector(15 downto 0) := (others => '0');
        o_dest_addr             : out std_logic_vector(15 downto 0) := (others => '0');
        o_checksum              : out std_logic_vector(15 downto 0) := (others => '0');
        o_port_controller_clock : out std_logic
    );
end header_extractor;

architecture behavioral of header_extractor is
type state_type is (PACKET_LENGTH, CHECKSUM, SEQ_NUM, FLAG, PROTOCOL, DUMMY, SOURCE_ADDRESS, DESTINATION_ADDRESS, PAYLOAD, FINISHED); 
signal STATE_REG                : state_type := PACKET_LENGTH; -- estado inicial setado como pl1
signal STATE_NEXT               : state_type;
        
signal PACKET_LENGTH_REG          : std_logic_vector(15 downto 0) := (others => '0');
signal PACKET_LENGTH_NEXT         : std_logic_vector(15 downto 0) := (others => '0');
        
signal SEQ_NUM_REG                : std_logic_vector(31 downto 0) := (others => '0');
signal SEQ_NUM_NEXT               : std_logic_vector(31 downto 0) := (others => '0');
        
signal SRC_ADDR_REG               : std_logic_vector(15 downto 0) := (others => '0');
signal SRC_ADDR_NEXT              : std_logic_vector(15 downto 0) := (others => '0');
        
signal DEST_ADDR_REG              : std_logic_vector(15 downto 0) := (others => '0');
signal DEST_ADDR_NEXT             : std_logic_vector(15 downto 0) := (others => '0');
        
signal CHECKSUM_REG               : std_logic_vector(15 downto 0) := (others => '0');
signal CHECKSUM_NEXT              : std_logic_vector(15 downto 0) := (others => '0');
        
signal FLAG_REG                   : std_logic_vector(07 downto 0) := (others => '0');
signal FLAG_NEXT                  : std_logic_vector(07 downto 0) := (others => '0');

signal PORT_CONTROLLER_CLOCK_REG  : std_logic := '0';
signal PORT_CONTROLLER_CLOCK_NEXT : std_logic := '0';

signal CTRL_REG                   : std_logic_vector(1 downto 0) := "00";
signal CTRL_NEXT                  : std_logic_vector(1 downto 0) := "00";

begin
    -- atualização de estado
    process(i_clk)
    begin
        if(rising_edge(i_clk)) then
            STATE_REG               <= STATE_NEXT;
            PACKET_LENGTH_REG         <= PACKET_LENGTH_NEXT;
            SEQ_NUM_REG               <= SEQ_NUM_NEXT;
            SRC_ADDR_REG              <= SRC_ADDR_NEXT;
            DEST_ADDR_REG             <= DEST_ADDR_NEXT;
            CHECKSUM_REG              <= CHECKSUM_NEXT;
            FLAG_REG                  <= FLAG_NEXT;
            PORT_CONTROLLER_CLOCK_REG <= PORT_CONTROLLER_CLOCK_NEXT;
            CTRL_REG                  <= CTRL_NEXT;
        end if;
    end process;

    -- lógica de próximo estado
    process(STATE_REG, CTRL_REG, S_AXIS_T_VALID, S_AXIS_T_READY, S_AXIS_T_LAST)
    begin
        --default value
        STATE_NEXT <= STATE_REG;

        case(STATE_REG) is
            when PACKET_LENGTH =>
                if (S_AXIS_T_VALID = '1' and S_AXIS_T_READY = '1') then
                    if (S_AXIS_T_LAST = '1') then 
                        STATE_NEXT <= FINISHED;
                    elsif(CTRL_REG = "01") then
                        STATE_NEXT <= CHECKSUM;
                    end if;
                end if;

            when CHECKSUM =>
                if (S_AXIS_T_VALID = '1' and S_AXIS_T_READY = '1') then
                    if (S_AXIS_T_LAST = '1') then 
                        STATE_NEXT <= FINISHED;
                    elsif(CTRL_REG = "01") then
                        STATE_NEXT <= SEQ_NUM;
                    end if;
                end if;

            when SEQ_NUM =>
                if (S_AXIS_T_VALID = '1' and S_AXIS_T_READY = '1') then
                    if (S_AXIS_T_LAST = '1') then 
                        STATE_NEXT <= FINISHED;
                    elsif(CTRL_REG = "11") then
                        STATE_NEXT <= FLAG;
                    end if;
                end if;

            when FLAG =>
                if (S_AXIS_T_VALID = '1' and S_AXIS_T_READY = '1') then
                    if (S_AXIS_T_LAST = '1') then 
                        STATE_NEXT <= FINISHED;
                    else
                        STATE_NEXT <= PROTOCOL;
                    end if;
                end if;
            when PROTOCOL =>
                if (S_AXIS_T_VALID = '1' and S_AXIS_T_READY = '1') then
                    if (S_AXIS_T_LAST = '1') then 
                        STATE_NEXT <= FINISHED;
                    else
                        STATE_NEXT <= DUMMY;
                    end if;
                end if;
            when DUMMY  =>
                if (S_AXIS_T_VALID = '1' and S_AXIS_T_READY = '1') then
                    if (S_AXIS_T_LAST = '1') then 
                        STATE_NEXT <= FINISHED;
                    elsif(CTRL_REG = "01") then
                        STATE_NEXT <= SOURCE_ADDRESS;
                    end if;
                end if;

            when SOURCE_ADDRESS =>
                if (S_AXIS_T_VALID = '1' and S_AXIS_T_READY = '1') then
                    if (S_AXIS_T_LAST = '1') then 
                        STATE_NEXT <= FINISHED;
                    elsif(CTRL_REG = "01") then
                        STATE_NEXT <= DESTINATION_ADDRESS;
                    end if;
                end if;

            when DESTINATION_ADDRESS     =>
                if (S_AXIS_T_VALID = '1' and S_AXIS_T_READY = '1') then
                    if (S_AXIS_T_LAST = '1') then 
                        STATE_NEXT <= FINISHED;
                    elsif(CTRL_REG = "01") then
                        STATE_NEXT <= PAYLOAD;
                    end if;
                end if;

            when PAYLOAD  =>
                if (S_AXIS_T_VALID = '1' and S_AXIS_T_READY = '1' and S_AXIS_T_LAST = '1') then
                    STATE_NEXT <= FINISHED;
                end if;
            when FINISHED =>
                if (S_AXIS_T_VALID = '1' and S_AXIS_T_READY = '1' and S_AXIS_T_LAST = '0') then
                    --STATE_NEXT <= PACKET_LENGTH_2;
                    STATE_NEXT <= PACKET_LENGTH;
                end if;
        end case;
    end process;

    -- datapath
    process(STATE_REG, PACKET_LENGTH_REG,CHECKSUM_REG,SEQ_NUM_REG,SRC_ADDR_REG,DEST_ADDR_REG, FLAG_REG, CTRL_REG, S_AXIS_T_DATA)
    begin
        -- dafault values
        PACKET_LENGTH_NEXT         <= PACKET_LENGTH_REG;
        CHECKSUM_NEXT              <= CHECKSUM_REG;
        SEQ_NUM_NEXT               <= SEQ_NUM_REG;
        SRC_ADDR_NEXT              <= SRC_ADDR_REG;
        DEST_ADDR_NEXT             <= DEST_ADDR_REG;
        FLAG_NEXT                  <= FLAG_REG;
        PORT_CONTROLLER_CLOCK_NEXT <= PORT_CONTROLLER_CLOCK_REG;
        CTRL_NEXT                  <= CTRL_REG; 

        case(STATE_REG) is
            when PACKET_LENGTH =>
                case CTRL_REG is
                    when "00" =>
                        PORT_CONTROLLER_CLOCK_NEXT <= '0';
                        PACKET_LENGTH_NEXT(15 downto 8) <= S_AXIS_T_DATA;
                        CTRL_NEXT <= "01";
                    when "01" =>
                        PORT_CONTROLLER_CLOCK_NEXT <= '0';
                        PACKET_LENGTH_NEXT(07 downto 0) <= S_AXIS_T_DATA;
                        CTRL_NEXT <= "00";
                    when others =>
                end case;

            when CHECKSUM =>
                case CTRL_REG is
                    when "00" =>
                        PORT_CONTROLLER_CLOCK_NEXT <= '0';
                        o_packet_length <= PACKET_LENGTH_REG;
                        CHECKSUM_NEXT(15 downto 8) <= S_AXIS_T_DATA;
                        CTRL_NEXT <= "01";
                    when "01" =>
                        PORT_CONTROLLER_CLOCK_NEXT <= '0';
                        CHECKSUM_NEXT(7 downto 0)  <= S_AXIS_T_DATA;
                        CTRL_NEXT <= "00";
                    when others =>
                end case;

            when SEQ_NUM =>
                case CTRL_REG is
                    when "00" =>
                        o_checksum <= CHECKSUM_REG;
                        SEQ_NUM_NEXT(31 downto 24) <= S_AXIS_T_DATA;
                        CTRL_NEXT <= "01";
                    when "01" =>
                        SEQ_NUM_NEXT(23 downto 16) <= S_AXIS_T_DATA;
                        CTRL_NEXT <= "10";
                    when "10" =>
                        SEQ_NUM_NEXT(15 downto 8)  <= S_AXIS_T_DATA;
                        CTRL_NEXT <= "11";
                    when "11" =>
                        SEQ_NUM_NEXT(7 downto 0)   <= S_AXIS_T_DATA;
                        CTRL_NEXT <= "00";
                    when others =>
                end case;

            when FLAG =>
                o_seq_num <= SEQ_NUM_REG;
                PORT_CONTROLLER_CLOCK_NEXT <= '1'; -- SEQ NUM CAPTURE
                FLAG_NEXT <= S_AXIS_T_DATA;

            when PROTOCOL =>
                PORT_CONTROLLER_CLOCK_NEXT <= '0';
                o_flag <= FLAG_REG;

            when DUMMY =>
                case CTRL_REG is
                    when "00" =>
                        PORT_CONTROLLER_CLOCK_NEXT <= '1'; -- FLAG CAPTURE
                        CTRL_NEXT <= "01";
                    when "01" =>
                        PORT_CONTROLLER_CLOCK_NEXT <= '0';
                        CTRL_NEXT <= "00";
                    when others =>
                end case;

            when SOURCE_ADDRESS =>
                case CTRL_REG is
                    when "00" =>
                        SRC_ADDR_NEXT(15 downto 8) <= S_AXIS_T_DATA;
                        CTRL_NEXT <= "01";
                    when "01" =>
                        SRC_ADDR_NEXT(7 downto 0)  <= S_AXIS_T_DATA;
                        CTRL_NEXT <= "00";
                    when others =>
                end case;

            when DESTINATION_ADDRESS =>
                case CTRL_REG is
                    when "00" =>
                        o_src_addr <= SRC_ADDR_REG;
                        PORT_CONTROLLER_CLOCK_NEXT <= '1';  -- SOURCE ADDRESS CAPTURE
                        DEST_ADDR_NEXT(15 downto 8) <= S_AXIS_T_DATA;
                        CTRL_NEXT <= "01";
                    when "01" =>
                        PORT_CONTROLLER_CLOCK_NEXT <= '0';
                        DEST_ADDR_NEXT(7 downto 0)  <= S_AXIS_T_DATA;
                        CTRL_NEXT <= "00";
                    when others =>
                end case;

            when PAYLOAD  =>
                o_dest_addr <= DEST_ADDR_REG;
                PORT_CONTROLLER_CLOCK_NEXT <= '1';  -- DESTINATION ADDRESS CAPTURE
            
            when FINISHED =>
                o_dest_addr <= DEST_ADDR_REG;
                PORT_CONTROLLER_CLOCK_NEXT <= '1';
                PACKET_LENGTH_NEXT(15 downto 8) <= S_AXIS_T_DATA;
                CTRL_NEXT                       <= "01";
                SEQ_NUM_NEXT                    <= (others => '0');
                SRC_ADDR_NEXT                   <= (others => '0');
                DEST_ADDR_NEXT                  <= (others => '0');
                CHECKSUM_NEXT                   <= (others => '0');
                FLAG_NEXT                       <= (others => '0');

            when others =>
        end case;

    end process;

    o_port_controller_clock <= PORT_CONTROLLER_CLOCK_REG;
end behavioral;
