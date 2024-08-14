library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity output_controller is
    port(
        -- master interface input ports ports
        slave_i_clk               : in  std_logic;
        S_AXIS_T_LAST             : in  std_logic;
        i_flag                    : in  std_logic_vector(06 downto 0);
        i_calc_checksum           : in  std_logic_vector(15 downto 0); -- 2 clock cycles
        i_dest_addr               : in  std_logic_vector(15 downto 0); -- 2 clock cycles
        i_seq_num_expected        : in  std_logic_vector(31 downto 0); -- 4 clock cycles
        i_packet_length_expected  : in  std_logic_vector(15 downto 0); -- 2 clock cycles
        i_dest_port               : in  std_logic_vector(04 downto 0);
               
        M_AXIS_TREADY             : in  std_logic;
        M_AXIS_TVALID             : out std_logic;
        M_AXIS_TLAST              : out std_logic;
        M_AXIS_TDATA              : out std_logic_vector(07 downto 0);
    
        master_o_dest_port        : out std_logic_vector(04 downto 0);
        master_o_dest_addr        : out std_logic_vector(15 downto 0);
        master_o_flags            : out std_logic_vector(06 downto 0)
    );
end output_controller;

architecture behavioral of output_controller is
type state_type is (IDLE, START, EXEC);
signal STATE_REG                        : state_type := IDLE; -- por padrão o estado começa como idle
signal STATE_NEXT                       : state_type;

signal FLAGS_REG                        : std_logic_vector(06 downto 0);
signal FLAGS_NEXT                       : std_logic_vector(06 downto 0);

signal CALC_CHECKSUM_REG                : std_logic_vector(15 downto 0) := (others => '0');
signal CALC_CHECKSUM_NEXT               : std_logic_vector(15 downto 0) := (others => '0');

signal DEST_ADDR_REG                    : std_logic_vector(15 downto 0) := (others => '0');
signal DEST_ADDR_NEXT                   : std_logic_vector(15 downto 0) := (others => '0');

signal SEQ_NUM_EXPECTED_REG             : std_logic_vector(31 downto 0) := (others => '0');
signal SEQ_NUM_EXPECTED_NEXT            : std_logic_vector(31 downto 0) := (others => '0');

signal PACKET_LENGTH_REG                : std_logic_vector(15 downto 0) := (others => '0');
signal PACKET_LENGTH_NEXT               : std_logic_vector(15 downto 0) := (others => '0');

signal CTRL_REG                         : std_logic_vector(03 downto 0) := (others => '0');
signal CTRL_NEXT                        : std_logic_vector(03 downto 0) := (others => '0');


signal w_master_valid                   : std_logic := '0';
signal w_master_last                    : std_logic := '0';

signal estado : std_logic_vector(1 downto 0);

begin

    estado <= "00" when STATE_REG = IDLE else
              "01" when STATE_REG = START else
              "10" when STATE_REG = EXEC;

    process(slave_i_clk)
    begin
        if(rising_edge(slave_i_clk)) then
            STATE_REG            <= STATE_NEXT;
            FLAGS_REG            <= FLAGS_NEXT;
            CALC_CHECKSUM_REG    <= CALC_CHECKSUM_NEXT;
            DEST_ADDR_REG        <= DEST_ADDR_NEXT;
            SEQ_NUM_EXPECTED_REG <= SEQ_NUM_EXPECTED_NEXT;
            PACKET_LENGTH_REG    <= PACKET_LENGTH_NEXT;
            CTRL_REG             <= CTRL_NEXT;
        end if;
    end process;

    process(STATE_REG, S_AXIS_T_LAST)
    begin
        -- default value
        STATE_NEXT <= STATE_REG;
        case STATE_REG is
            when IDLE =>
                if(S_AXIS_T_LAST = '1') then
                    STATE_NEXT <= START;
                elsif(M_AXIS_TREADY = '1') then
                    STATE_NEXT <= EXEC;
                end if;
            when START =>
                if(M_AXIS_TREADY = '1') then
                    STATE_NEXT <= EXEC;
                else
                    STATE_NEXT <= IDLE;
                end if;
            when EXEC =>

            when others =>
        end case;
    end process;

    process(STATE_REG, FLAGS_REG, CALC_CHECKSUM_REG, DEST_ADDR_REG, SEQ_NUM_EXPECTED_REG, PACKET_LENGTH_REG, S_AXIS_T_LAST, i_flag)
    begin
        -- Default values
        CTRL_NEXT <= CTRL_REG;
        
        case STATE_REG is
            when idle =>
                w_master_valid <= '0';
                w_master_last  <= '0';

            when START =>
                w_master_valid <= '0';
                w_master_last  <= '0';

                if(S_AXIS_T_LAST = '1') then
                    -- Esses sinais não podem receber atribuião padrão no início do process
                    FLAGS_NEXT            <= i_flag;
                    CALC_CHECKSUM_NEXT    <= i_calc_checksum;
                    DEST_ADDR_NEXT        <= i_dest_addr;
                    SEQ_NUM_EXPECTED_NEXT <= i_seq_num_expected;
                    PACKET_LENGTH_NEXT    <= i_packet_length_expected;

                    if   (FLAGS_REG(0) = '1') then -- packet_length error
                        CTRL_NEXT <= "0000";
                    elsif(FLAGS_REG(1) = '1') then -- checksum error
                        CTRL_NEXT <= "0010";
                    elsif(FLAGS_REG(2) = '1') then -- seq_num error
                        CTRL_NEXT <= "0100";
                    elsif(FLAGS_REG(3) = '1') then -- destination address not found
                        CTRL_NEXT <= "1000";
                    end if; 

                end if;

            when EXEC =>
                w_master_valid <= '1';
                w_master_last  <= '0';

                case CTRL_REG is
                    when "0000" => -- packet_length 1
                        if(M_AXIS_TREADY = '1') then
                            M_AXIS_TDATA <= PACKET_LENGTH_REG(15 downto 8);
                            CTRL_NEXT <= "0001";
                        end if;
                    when "0001" => -- packet_length 2
                        if(M_AXIS_TREADY = '1') then
                            M_AXIS_TDATA <= PACKET_LENGTH_REG(07 downto 0);
                        end if;

                        if   (FLAGS_REG(1) = '1') then -- checksum error
                            CTRL_NEXT <= "0010";
                        elsif(FLAGS_REG(2) = '1') then -- seq_num error
                            CTRL_NEXT <= "0100";
                        elsif(FLAGS_REG(3) = '1') then -- destination address not found
                            CTRL_NEXT <= "1000";
                        else
                            w_master_last <= '1';
                        end if; 

                    when "0010" => -- checksum 1
                        if(M_AXIS_TREADY = '1') then
                            M_AXIS_TDATA <= CALC_CHECKSUM_REG(15 downto 8);
                            CTRL_NEXT <= "0001";
                        end if;
                    when "0011" => -- checksum 2
                        if(M_AXIS_TREADY = '1') then
                            M_AXIS_TDATA <= CALC_CHECKSUM_REG(07 downto 0);
                        end if;

                        if   (FLAGS_REG(2) = '1') then -- seq_num error
                            CTRL_NEXT <= "0100";
                        elsif(FLAGS_REG(3) = '1') then -- destination address not found
                            CTRL_NEXT <= "1000";
                        else
                            w_master_last <= '1';
                        end if; 

                    when "0100" => -- seq_num 1
                        if(M_AXIS_TREADY = '1') then
                            M_AXIS_TDATA <= SEQ_NUM_EXPECTED_REG(31 downto 24);
                            CTRL_NEXT <= "0001";
                        end if;
                    when "0101" => -- seq_num 2
                        if(M_AXIS_TREADY = '1') then
                            M_AXIS_TDATA <= SEQ_NUM_EXPECTED_REG(23 downto 16);
                            CTRL_NEXT <= "0001";
                        end if;
                    when "0110" => -- seq_num 3
                        if(M_AXIS_TREADY = '1') then
                            M_AXIS_TDATA <= SEQ_NUM_EXPECTED_REG(15 downto 8);
                            CTRL_NEXT <= "0001";
                        end if;
                    when "0111" => -- seq_num 4
                        if(M_AXIS_TREADY = '1') then
                            M_AXIS_TDATA <= SEQ_NUM_EXPECTED_REG(07 downto 0);
                        end if;

                        if(FLAGS_REG(3) = '1') then -- destination address not found
                            CTRL_NEXT <= "1000";
                        else
                            w_master_last <= '1';
                        end if; 
                    when "1000" => -- dest_addr 1
                        if(M_AXIS_TREADY = '1') then
                            M_AXIS_TDATA <= DEST_ADDR_REG(15 downto 8);
                            CTRL_NEXT <= "0001";
                        end if;
                    when "1001" => -- dest_addr 2
                        w_master_last <= '1';
                        if(M_AXIS_TREADY = '1') then
                            M_AXIS_TDATA <= DEST_ADDR_REG(07 downto 0);
                        end if;

                    when others =>
                end case;
            when others =>
        end case;
    end process;

    master_o_dest_port <= i_dest_port;
    master_o_dest_addr <= i_dest_addr;
    master_o_flags     <= i_flag;

    M_AXIS_TVALID      <= w_master_valid;
    M_AXIS_TLAST       <= w_master_last;

end behavioral;