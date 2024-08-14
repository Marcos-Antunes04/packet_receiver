library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity output_controller is
    port(
        -- master interface input ports ports
        slave_i_clk               : in std_logic;
        S_AXIS_T_LAST             : in std_logic;
        i_flag                    : in std_logic_vector(06 downto 0);
        i_calc_checksum           : in std_logic_vector(15 downto 0); -- 2 clock cycles
        i_dest_addr               : in std_logic_vector(15 downto 0); -- 2 clock cycles
        i_seq_num_expected        : in std_logic_vector(31 downto 0); -- 4 clock cycles
        i_packet_length_expected  : in std_logic_vector(15 downto 0); -- 2 clock cycles
        i_dest_port               : in std_logic_vector(04 downto 0);

        -- controle da transmissão de checksum esperado
        o_calc_checksum_valid : out std_logic;
        i_calc_checksum_ready : in  std_logic;

        -- controle da transmissão de seq_num esperado
        o_seq_num_expected_valid : out std_logic;
        i_seq_num_expected_ready : in  std_logic;

        -- controle da transmissão de payload_length esperado
        o_payload_length_expected_valid : out std_logic;
        i_payload_length_expected_ready : in  std_logic;
               
        master_i_ready        : in  std_logic;
        master_o_valid        : out std_logic;
        master_o_last         : out std_logic;
        master_o_data         : out std_logic_vector(07 downto 0);

        master_o_dest_port    : out std_logic_vector(04 downto 0);
        master_o_dest_addr    : out std_logic_vector(15 downto 0);
        master_o_flags        : out std_logic_vector(06 downto 0)
    );
end output_controller;

architecture behavioral of output_controller is
type state_type is (IDLE, START, CALC_CHECKSUM_SENT, EXPECTED_SEQ_NUM_SENT, EXPECTED_PACKET_LENGTH_SENT);
signal STATE_REG              : state_type := IDLE; -- por padrão o estado começa como idle
signal STATE_NEXT             : state_type;

signal FLAGS_REG              : std_logic_vector(06 downto 0);
signal FLAGS_NEXT              : std_logic_vector(06 downto 0);

signal CALC_CHECKSUM_REG              : std_logic_vector(06 downto 0);
signal CALC_CHECKSUM_NEXT              : std_logic_vector(06 downto 0);

signal DEST_ADDR_REG              : std_logic_vector(06 downto 0);
signal DEST_ADDR_NEXT              : std_logic_vector(06 downto 0);

signal SEQ_NUM_EXPECTED_REG              : std_logic_vector(06 downto 0);
signal SEQ_NUM_EXPECTED_NEXT              : std_logic_vector(06 downto 0);

signal PACKET_LENGTH_REG              : std_logic_vector(06 downto 0);
signal PACKET_LENGTH_NEXT              : std_logic_vector(06 downto 0);

signal DEST_PORT_REG              : std_logic_vector(06 downto 0);
signal DEST_PORT_NEXT              : std_logic_vector(06 downto 0);

begin
    process(STATE_REG)
    begin
        if(rising_edge(slave_i_clk)) then
            STATE_REG <= STATE_NEXT;
        end if;
    end process;

    process(STATE_REG, S_AXIS_T_LAST)
    begin
        -- default value
        STATE_NEXT <= STATE_REG;
        case STATE_REG is
            when idle =>
                if(S_AXIS_T_LAST = '1') then
                    STATE_NEXT <= START;
                end if;
            when START =>

            when CALC_CHECKSUM_SENT =>

            when EXPECTED_SEQ_NUM_SENT =>

            when EXPECTED_PACKET_LENGTH_SENT =>

            when others =>
        end case;
    end process;

    process(STATE_REG, S_AXIS_T_LAST)
    begin
        case STATE_REG is
            when idle =>

            when START =>
                if(S_AXIS_T_LAST = '1') then

                    
                end if;

            when CALC_CHECKSUM_SENT =>

            when EXPECTED_SEQ_NUM_SENT =>

            when EXPECTED_PACKET_LENGTH_SENT =>

            when others =>
        end case;
    end process;

    master_o_dest_port <= i_dest_port;
    master_o_dest_addr <= i_dest_addr;
    master_o_flags     <= i_flag;
end behavioral;
