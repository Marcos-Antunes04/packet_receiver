library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity header_extractor is
    port(
        -- input ports
        i_clk   : in std_logic;
        i_valid : in std_logic;
        i_last  : in std_logic;
        i_ready : in std_logic;
        i_data  : in std_logic_vector(7 downto 0);
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
type state_type is (PACKET_LENGTH_1, PACKET_LENGTH_2,CHECKSUM_1, CHECKSUM_2, SEQ_NUM_1, SEQ_NUM_2, SEQ_NUM_3, SEQ_NUM_4, FLAG, PROTOCOL, DUMMY_1, DUMMY_2, SOURCE_ADDRESS_1, SOURCE_ADDRESS_2, DESTINATION_ADDRESS_1, DESTINATION_ADDRESS_2, PAYLOAD, FINISHED); 
signal r_STATE_REG                : state_type := PACKET_LENGTH_1; -- estado inicial setado como pl1
signal r_STATE_NEXT               : state_type;
        
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

signal estado : std_logic_vector(4 downto 0);
begin

    estado <= "00000" when r_STATE_REG = PACKET_LENGTH_1 else
              "00001" when r_STATE_REG = PACKET_LENGTH_2 else
              "00010" when r_STATE_REG = CHECKSUM_1 else
              "00011" when r_STATE_REG = CHECKSUM_2 else
              "00100" when r_STATE_REG = SEQ_NUM_1 else
              "00101" when r_STATE_REG = SEQ_NUM_2 else
              "00110" when r_STATE_REG = SEQ_NUM_3 else
              "00111" when r_STATE_REG = SEQ_NUM_4 else
              "01000" when r_STATE_REG = FLAG else
              "01001" when r_STATE_REG = PROTOCOL else
              "01010" when r_STATE_REG = DUMMY_1 else
              "01011" when r_STATE_REG = DUMMY_2 else
              "01100" when r_STATE_REG = SOURCE_ADDRESS_1 else
              "01101" when r_STATE_REG = SOURCE_ADDRESS_2 else
              "01110" when r_STATE_REG = DESTINATION_ADDRESS_1 else
              "01111" when r_STATE_REG = DESTINATION_ADDRESS_2 else
              "10000" when r_STATE_REG = PAYLOAD else
              "10001" when r_STATE_REG = FINISHED;

    -- atualização de estado
    process(i_clk)
    begin
        if(rising_edge(i_clk)) then
            r_STATE_REG               <= r_STATE_NEXT;
            PACKET_LENGTH_REG         <= PACKET_LENGTH_NEXT;
            SEQ_NUM_REG               <= SEQ_NUM_NEXT;
            SRC_ADDR_REG              <= SRC_ADDR_NEXT;
            DEST_ADDR_REG             <= DEST_ADDR_NEXT;
            CHECKSUM_REG              <= CHECKSUM_NEXT;
            FLAG_REG                  <= FLAG_NEXT;
            PORT_CONTROLLER_CLOCK_REG <= PORT_CONTROLLER_CLOCK_NEXT;
        end if;
    end process;

    -- lógica de próximo estado
    process(r_STATE_REG, i_valid, i_ready, i_last)
    begin
        --default value
        r_STATE_NEXT <= r_STATE_REG;

        case(r_STATE_REG) is
            when PACKET_LENGTH_1     =>
                if (i_valid = '1' and i_ready = '1') then
                    if (i_last = '1') then 
                        r_STATE_NEXT <= FINISHED;
                    else
                        r_STATE_NEXT <= PACKET_LENGTH_2;
                    end if;
                end if;
            when PACKET_LENGTH_2     =>
                if (i_valid = '1' and i_ready = '1') then
                    if (i_last = '1') then 
                        r_STATE_NEXT <= FINISHED;
                    else
                        r_STATE_NEXT <= CHECKSUM_1;
                    end if;
                end if;
            when CHECKSUM_1     =>
                if (i_valid = '1' and i_ready = '1') then
                    if (i_last = '1') then 
                        r_STATE_NEXT <= FINISHED;
                    else
                        r_STATE_NEXT <= CHECKSUM_2;
                    end if;
                end if;
            when CHECKSUM_2     =>
                if (i_valid = '1' and i_ready = '1') then
                    if (i_last = '1') then 
                        r_STATE_NEXT <= FINISHED;
                    else
                        r_STATE_NEXT <= SEQ_NUM_1;
                    end if;
                end if;
            when SEQ_NUM_1     =>
                if (i_valid = '1' and i_ready = '1') then
                    if (i_last = '1') then 
                        r_STATE_NEXT <= FINISHED;
                    else
                        r_STATE_NEXT <= SEQ_NUM_2;
                    end if;
                end if;
            when SEQ_NUM_2     =>
                if (i_valid = '1' and i_ready = '1') then
                    if (i_last = '1') then 
                        r_STATE_NEXT <= FINISHED;
                    else
                        r_STATE_NEXT <= SEQ_NUM_3;
                    end if;
                end if;
            when SEQ_NUM_3     =>
                if (i_valid = '1' and i_ready = '1') then
                    if (i_last = '1') then 
                        r_STATE_NEXT <= FINISHED;
                    else
                        r_STATE_NEXT <= SEQ_NUM_4;
                    end if;
                end if;
            when SEQ_NUM_4     =>
                if (i_valid = '1' and i_ready = '1') then
                    if (i_last = '1') then 
                        r_STATE_NEXT <= FINISHED;
                    else
                        r_STATE_NEXT <= FLAG;
                    end if;
                end if;
            when FLAG     =>
                if (i_valid = '1' and i_ready = '1') then
                    if (i_last = '1') then 
                        r_STATE_NEXT <= FINISHED;
                    else
                        r_STATE_NEXT <= PROTOCOL;
                    end if;
                end if;
            when PROTOCOL =>
                if (i_valid = '1' and i_ready = '1') then
                    if (i_last = '1') then 
                        r_STATE_NEXT <= FINISHED;
                    else
                        r_STATE_NEXT <= DUMMY_1;
                    end if;
                end if;
            when DUMMY_1  =>
                if (i_valid = '1' and i_ready = '1') then
                    if (i_last = '1') then 
                        r_STATE_NEXT <= FINISHED;
                    else
                        r_STATE_NEXT <= DUMMY_2;
                    end if;
                end if;
            when DUMMY_2  =>
                if (i_valid = '1' and i_ready = '1') then
                    if (i_last = '1') then 
                        r_STATE_NEXT <= FINISHED;
                    else
                        r_STATE_NEXT <= SOURCE_ADDRESS_1;
                    end if;
                end if;
            when SOURCE_ADDRESS_1     =>
                if (i_valid = '1' and i_ready = '1') then
                    if (i_last = '1') then 
                        r_STATE_NEXT <= FINISHED;
                    else
                        r_STATE_NEXT <= SOURCE_ADDRESS_2;
                    end if;
                end if;
            when SOURCE_ADDRESS_2     =>
                if (i_valid = '1' and i_ready = '1') then
                    if (i_last = '1') then 
                        r_STATE_NEXT <= FINISHED;
                    else
                        r_STATE_NEXT <= DESTINATION_ADDRESS_1;
                    end if;
                end if;
            when DESTINATION_ADDRESS_1     =>
                if (i_valid = '1' and i_ready = '1') then
                    if (i_last = '1') then 
                        r_STATE_NEXT <= FINISHED;
                    else
                        r_STATE_NEXT <= DESTINATION_ADDRESS_2;
                    end if;
                end if;
            when DESTINATION_ADDRESS_2     =>
                if (i_valid = '1' and i_ready = '1') then
                    if (i_last = '1') then 
                        r_STATE_NEXT <= FINISHED;
                    else
                        r_STATE_NEXT <= PAYLOAD;
                    end if;
                end if;
            when PAYLOAD  =>
                if (i_valid = '1' and i_ready = '1' and i_last = '1') then
                    r_STATE_NEXT <= FINISHED;
                end if;
            when FINISHED =>
                if (i_valid = '1' and i_ready = '1' and i_last = '0') then
                    r_STATE_NEXT <= PACKET_LENGTH_1;
                end if;
        end case;
    end process;

    -- datapath
    process(r_STATE_REG, PACKET_LENGTH_REG,CHECKSUM_REG,SEQ_NUM_REG,SRC_ADDR_REG,DEST_ADDR_REG, FLAG_REG, i_data)
    begin
        -- dafault values
        PACKET_LENGTH_NEXT         <= PACKET_LENGTH_REG;
        CHECKSUM_NEXT              <= CHECKSUM_REG;
        SEQ_NUM_NEXT               <= SEQ_NUM_REG;
        SRC_ADDR_NEXT              <= SRC_ADDR_REG;
        DEST_ADDR_NEXT             <= DEST_ADDR_REG;
        FLAG_NEXT                  <= FLAG_REG;
        PORT_CONTROLLER_CLOCK_NEXT <= PORT_CONTROLLER_CLOCK_REG;

        case(r_STATE_REG) is
            -- packet length
            when PACKET_LENGTH_1     =>
                PORT_CONTROLLER_CLOCK_NEXT <= '0';
                PACKET_LENGTH_NEXT(15 downto 8) <= i_data;
            when PACKET_LENGTH_2     =>
                PORT_CONTROLLER_CLOCK_NEXT <= '0';
                PACKET_LENGTH_NEXT(7 downto 0)  <= i_data;

            -- checksum
            when CHECKSUM_1     =>
                PORT_CONTROLLER_CLOCK_NEXT <= '0';
                o_packet_length <= PACKET_LENGTH_REG;
                CHECKSUM_NEXT(15 downto 8) <= i_data;
            when CHECKSUM_2     =>
                PORT_CONTROLLER_CLOCK_NEXT <= '0';
                CHECKSUM_NEXT(7 downto 0)  <= i_data;

            -- sequence number
            when SEQ_NUM_1     =>
                o_checksum <= CHECKSUM_REG;
                SEQ_NUM_NEXT(31 downto 24) <= i_data;
            when SEQ_NUM_2     =>
                SEQ_NUM_NEXT(23 downto 16) <= i_data;
            when SEQ_NUM_3     =>
                SEQ_NUM_NEXT(15 downto 8)  <= i_data;
            when SEQ_NUM_4     =>
                SEQ_NUM_NEXT(7 downto 0)   <= i_data;

            -- FLAG
            when FLAG     =>
                o_seq_num <= SEQ_NUM_REG;
                PORT_CONTROLLER_CLOCK_NEXT <= '1';
                FLAG_NEXT <= i_data;

            when PROTOCOL =>
                PORT_CONTROLLER_CLOCK_NEXT <= '0';
                o_flag <= FLAG_REG;
            when DUMMY_1  =>
                PORT_CONTROLLER_CLOCK_NEXT <= '1';
            when DUMMY_2  =>
                PORT_CONTROLLER_CLOCK_NEXT <= '0';

            -- source address
            when SOURCE_ADDRESS_1     =>
                SRC_ADDR_NEXT(15 downto 8) <= i_data;
            when SOURCE_ADDRESS_2     =>
                SRC_ADDR_NEXT(7 downto 0)  <= i_data;

            -- destination address
            when DESTINATION_ADDRESS_1     =>
                o_src_addr <= SRC_ADDR_REG;
                PORT_CONTROLLER_CLOCK_NEXT <= '1';
                DEST_ADDR_NEXT(15 downto 8) <= i_data;
            when DESTINATION_ADDRESS_2     =>
                PORT_CONTROLLER_CLOCK_NEXT <= '0';
                DEST_ADDR_NEXT(7 downto 0)  <= i_data;

            -- PAYLOAD
            when PAYLOAD  =>
                o_dest_addr <= DEST_ADDR_REG;
                PORT_CONTROLLER_CLOCK_NEXT <= '1';
            
            -- FINISHED state
            when FINISHED =>
                o_dest_addr <= DEST_ADDR_REG;
                PORT_CONTROLLER_CLOCK_NEXT <= '1';
                PACKET_LENGTH_NEXT(15 downto 8) <= i_data;
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
