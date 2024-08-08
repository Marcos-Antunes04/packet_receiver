library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity header_extractor is
    port(
        -- input ports
        i_clk, i_valid, i_last : in std_logic;
        o_ready: out std_logic;
        i_data : in std_logic_vector(7 downto 0);
        -- output ports        
        o_packet_length         : out std_logic_vector(15 downto 0) := (others => '0');
        o_FLAG                  : out std_logic_vector(07 downto 0) := (others => '0');
        o_seq_num               : out std_logic_vector(31 downto 0) := (others => '0');
        o_src_addr              : out std_logic_vector(15 downto 0) := (others => '0');
        o_dest_addr             : out std_logic_vector(15 downto 0) := (others => '0');
        o_checksum              : out std_logic_vector(15 downto 0) := (others => '0');
        o_port_controller_clock : out std_logic
    );
end header_extractor;

architecture behavioral of header_extractor is
type state_type is (IDLE, PACKET_LENGTH_1, PACKET_LENGTH_2,CHECKSUM_1, CHECKSUM_2, SEQ_NUM_1, SEQ_NUM_2, SEQ_NUM_3, SEQ_NUM_4, FLAG, PROTOCOL, DUMMY_1, DUMMY_2, SOURCE_ADDRESS_1, SOURCE_ADDRESS_2, destination_address_1, DESTINATION_ADDRESS_2, PAYLOAD, finished); 
signal r_STATE_REG  : state_type := PACKET_LENGTH_1;
signal r_STATE_NEXT : state_type;
signal PACKET_LENGTH_REG, packet_length_next : std_logic_vector(15 downto 0) := (others => '0');
signal SEQ_NUM_REG,SEQ_NUM_NEXT              : std_logic_vector(31 downto 0) := (others => '0');
signal SRC_ADDR_REG, SRC_ADDR_NEXT           : std_logic_vector(15 downto 0) := (others => '0');
signal DEST_ADDR_REG, DEST_ADDR_NEXT         : std_logic_vector(15 downto 0) := (others => '0');
signal CHECKSUM_REG, checksum_next           : std_logic_vector(15 downto 0) := (others => '0');
signal FLAG_REG, FLAG_NEXT                   : std_logic_vector(07 downto 0) := (others => '0');
signal PORT_CONTROLLER_CLOCK_REG,PORT_CONTROLLER_CLOCK_NEXT : std_logic := '0';
begin

    -- atualização de estado
    process(i_clk,i_last)
    begin
        if(i_valid = '0') then -- sinais que funcionam como enable síncrono
            r_STATE_REG <= IDLE;
            PACKET_LENGTH_REG <= PACKET_LENGTH_REG;
            SEQ_NUM_REG       <= SEQ_NUM_REG;
            SRC_ADDR_REG      <= SRC_ADDR_REG;
            DEST_ADDR_REG     <= DEST_ADDR_REG;
            CHECKSUM_REG      <= CHECKSUM_REG;
            FLAG_REG          <= FLAG_REG;
            PORT_CONTROLLER_CLOCK_REG <= PORT_CONTROLLER_CLOCK_REG;
        elsif(i_last = '1') then
            r_STATE_REG <= finished;
            PACKET_LENGTH_REG         <= packet_length_next;
            SEQ_NUM_REG               <= SEQ_NUM_NEXT;
            SRC_ADDR_REG              <= SRC_ADDR_NEXT;
            DEST_ADDR_REG             <= DEST_ADDR_NEXT;
            CHECKSUM_REG              <= checksum_next;
            FLAG_REG                  <= FLAG_NEXT;
            PORT_CONTROLLER_CLOCK_REG <= PORT_CONTROLLER_CLOCK_NEXT;
        elsif(rising_edge(i_clk)) then
            r_STATE_REG               <= r_STATE_NEXT;
            PACKET_LENGTH_REG         <= packet_length_next;
            SEQ_NUM_REG               <= SEQ_NUM_NEXT;
            SRC_ADDR_REG              <= SRC_ADDR_NEXT;
            DEST_ADDR_REG             <= DEST_ADDR_NEXT;
            CHECKSUM_REG              <= checksum_next;
            FLAG_REG                  <= FLAG_NEXT;
            PORT_CONTROLLER_CLOCK_REG <= PORT_CONTROLLER_CLOCK_NEXT;
        elsif(falling_edge(i_last)) then
            r_STATE_REG <= PACKET_LENGTH_1;
            PACKET_LENGTH_REG <= (others => '0');
            SEQ_NUM_REG       <= (others => '0');
            SRC_ADDR_REG      <= (others => '0');
            DEST_ADDR_REG     <= (others => '0');
            CHECKSUM_REG      <= (others => '0');
            FLAG_REG          <= (others => '0');
            PORT_CONTROLLER_CLOCK_REG <= '0';
        end if;
    end process;

    -- lógica de próximo estado
    r_STATE_NEXT <= PACKET_LENGTH_2     when r_STATE_REG = PACKET_LENGTH_1       else
                  CHECKSUM_1            when r_STATE_REG = PACKET_LENGTH_2       else
                  CHECKSUM_2            when r_STATE_REG = CHECKSUM_1            else 
                  SEQ_NUM_1             when r_STATE_REG = CHECKSUM_2            else
                  SEQ_NUM_2             when r_STATE_REG = SEQ_NUM_1             else
                  SEQ_NUM_3             when r_STATE_REG = SEQ_NUM_2             else
                  SEQ_NUM_4             when r_STATE_REG = SEQ_NUM_3             else
                  FLAG                  when r_STATE_REG = SEQ_NUM_4             else
                  PROTOCOL              when r_STATE_REG = FLAG                  else
                  DUMMY_1               when r_STATE_REG = PROTOCOL              else
                  DUMMY_2               when r_STATE_REG = DUMMY_1               else
                  SOURCE_ADDRESS_1      when r_STATE_REG = DUMMY_2               else
                  SOURCE_ADDRESS_2      when r_STATE_REG = SOURCE_ADDRESS_1      else
                  destination_address_1 when r_STATE_REG = SOURCE_ADDRESS_2      else
                  DESTINATION_ADDRESS_2 when r_STATE_REG = destination_address_1 else
                  PAYLOAD               when r_STATE_REG = DESTINATION_ADDRESS_2 else
                  PAYLOAD               when r_STATE_REG = PAYLOAD;


    -- operações de estado
    process(r_STATE_REG, PACKET_LENGTH_REG,CHECKSUM_REG,SEQ_NUM_REG,SRC_ADDR_REG,DEST_ADDR_REG, FLAG_REG, i_data)
    begin
        -- dafault values
        packet_length_next         <= PACKET_LENGTH_REG;
        checksum_next              <= CHECKSUM_REG;
        SEQ_NUM_NEXT               <= SEQ_NUM_REG;
        SRC_ADDR_NEXT              <= SRC_ADDR_REG;
        DEST_ADDR_NEXT             <= DEST_ADDR_REG;
        FLAG_NEXT                  <= FLAG_REG;
        PORT_CONTROLLER_CLOCK_NEXT <= PORT_CONTROLLER_CLOCK_REG;

        case(r_STATE_REG) is
            -- packet length
            when PACKET_LENGTH_1     =>
                PORT_CONTROLLER_CLOCK_NEXT <= '0';
                packet_length_next(15 downto 8) <= i_data;
            when PACKET_LENGTH_2     =>
                packet_length_next(7 downto 0)  <= i_data;

            -- checksum
            when CHECKSUM_1     =>
                o_packet_length <= PACKET_LENGTH_REG;
                checksum_next(15 downto 8) <= i_data;
            when CHECKSUM_2     =>
                checksum_next(7 downto 0)  <= i_data;

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
                o_FLAG <= FLAG_REG;
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
            when destination_address_1     =>
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
            
            -- finished state
            when finished =>
                o_dest_addr <= DEST_ADDR_REG;
                PORT_CONTROLLER_CLOCK_NEXT <= '1';

            -- eventually IDLE
            when others =>
        end case;

    end process;

    o_port_controller_clock <= PORT_CONTROLLER_CLOCK_REG;
end behavioral;
