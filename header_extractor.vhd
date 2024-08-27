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
type t_state_type is (PACKET_LENGTH, CHECKSUM, SEQ_NUM, FLAG, PROTOCOL, DUMMY, SOURCE_ADDRESS, DESTINATION_ADDRESS, PAYLOAD, FINISHED); 
signal state_reg                  : t_state_type := PACKET_LENGTH; -- estado inicial setado como pl1
signal state_next                 : t_state_type;
        
signal packet_length_reg          : std_logic_vector(15 downto 0) := (others => '0');
signal packet_length_next         : std_logic_vector(15 downto 0) := (others => '0');
        
signal seq_num_reg                : std_logic_vector(31 downto 0) := (others => '0');
signal seq_num_next               : std_logic_vector(31 downto 0) := (others => '0');
        
signal src_addr_reg               : std_logic_vector(15 downto 0) := (others => '0');
signal src_addr_next              : std_logic_vector(15 downto 0) := (others => '0');
        
signal dest_addr_reg              : std_logic_vector(15 downto 0) := (others => '0');
signal dest_addr_next             : std_logic_vector(15 downto 0) := (others => '0');
        
signal checksum_reg               : std_logic_vector(15 downto 0) := (others => '0');
signal checksum_next              : std_logic_vector(15 downto 0) := (others => '0');
        
signal flag_reg                   : std_logic_vector(07 downto 0) := (others => '0');
signal flag_next                  : std_logic_vector(07 downto 0) := (others => '0');

signal port_controller_clock_reg  : std_logic := '0';
signal port_controller_clock_next : std_logic := '0';

signal ctrl_reg                   : std_logic_vector(1 downto 0) := "00";
signal ctrl_next                  : std_logic_vector(1 downto 0) := "00";

begin
    -- atualização de estado
    process(i_clk)
    begin
        if(rising_edge(i_clk)) then
            state_reg                 <= state_next;
            packet_length_reg         <= packet_length_next;
            seq_num_reg               <= seq_num_next;
            src_addr_reg              <= src_addr_next;
            dest_addr_reg             <= dest_addr_next;
            checksum_reg              <= checksum_next;
            flag_reg                  <= flag_next;
            port_controller_clock_reg <= port_controller_clock_next;
            ctrl_reg                  <= ctrl_next;
        end if;
    end process;

    -- lógica de próximo estado
    process(state_reg, ctrl_reg, S_AXIS_T_VALID, S_AXIS_T_READY, S_AXIS_T_LAST)
    begin
        --default value
        state_next <= state_reg;

        if (S_AXIS_T_VALID = '1' and S_AXIS_T_READY = '1') then
            case(state_reg) is
                when PACKET_LENGTH =>
                        if (S_AXIS_T_LAST = '1') then 
                            state_next <= FINISHED;
                        elsif(ctrl_reg = "01") then
                            state_next <= CHECKSUM;
                        end if;

                when CHECKSUM =>
                        if (S_AXIS_T_LAST = '1') then 
                            state_next <= FINISHED;
                        elsif(ctrl_reg = "01") then
                            state_next <= SEQ_NUM;
                        end if;

                when SEQ_NUM =>
                        if (S_AXIS_T_LAST = '1') then 
                            state_next <= FINISHED;
                        elsif(ctrl_reg = "11") then
                            state_next <= FLAG;
                        end if;

                when FLAG =>
                        if (S_AXIS_T_LAST = '1') then 
                            state_next <= FINISHED;
                        else
                            state_next <= PROTOCOL;
                        end if;

                when PROTOCOL =>
                        if (S_AXIS_T_LAST = '1') then 
                            state_next <= FINISHED;
                        else
                            state_next <= DUMMY;
                        end if;

                when DUMMY  =>
                        if (S_AXIS_T_LAST = '1') then 
                            state_next <= FINISHED;
                        elsif(ctrl_reg = "01") then
                            state_next <= SOURCE_ADDRESS;
                        end if;

                when SOURCE_ADDRESS =>
                        if (S_AXIS_T_LAST = '1') then 
                            state_next <= FINISHED;
                        elsif(ctrl_reg = "01") then
                            state_next <= DESTINATION_ADDRESS;
                        end if;

                when DESTINATION_ADDRESS     =>
                        if (S_AXIS_T_LAST = '1') then 
                            state_next <= FINISHED;
                        elsif(ctrl_reg = "01") then
                            state_next <= PAYLOAD;
                        end if;

                when PAYLOAD  =>
                    if (S_AXIS_T_LAST = '1') then
                        state_next <= FINISHED;
                    end if;
                when FINISHED =>
                    if (S_AXIS_T_LAST = '0') then
                        state_next <= PACKET_LENGTH;
                    end if;
            end case;
        end if;
    end process;

    -- datapath
    process(state_reg, packet_length_reg,checksum_reg,seq_num_reg,src_addr_reg,dest_addr_reg, flag_reg, ctrl_reg, S_AXIS_T_DATA)
    begin
        -- dafault values
        packet_length_next         <= packet_length_reg;
        checksum_next              <= checksum_reg;
        seq_num_next               <= seq_num_reg;
        src_addr_next              <= src_addr_reg;
        dest_addr_next             <= dest_addr_reg;
        flag_next                  <= flag_reg;
        port_controller_clock_next <= port_controller_clock_reg;
        ctrl_next                  <= ctrl_reg; 

        case(state_reg) is
            when PACKET_LENGTH =>
                port_controller_clock_next <= '0';
                packet_length_next <= packet_length_next(07 downto 0) & S_AXIS_T_DATA;

                if(ctrl_reg = "00") then
                    ctrl_next <= "01";
                else
                    ctrl_next <= "00";
                end if;

            when CHECKSUM =>
                port_controller_clock_next <= '0';
                checksum_next <= checksum_next(07 downto 0) & S_AXIS_T_DATA;

                if(ctrl_reg = "00") then
                    ctrl_next <= "01";
                else
                    ctrl_next <= "00";
                end if;

            when SEQ_NUM =>
                seq_num_next <= seq_num_next(23 downto 0) & S_AXIS_T_DATA;

                if(ctrl_reg = "00") then
                    ctrl_next <= "01";
                elsif(ctrl_reg = "01") then
                    ctrl_next <= "10";
                elsif(ctrl_reg = "10") then
                    ctrl_next <= "11";
                else
                    ctrl_next <= "00";
                end if;

            when FLAG =>
                port_controller_clock_next <= '1'; -- SEQ NUM CAPTURE
                flag_next <= S_AXIS_T_DATA;

            when PROTOCOL =>
                port_controller_clock_next <= '0';

            when DUMMY =>
                if(ctrl_reg = "00") then
                        port_controller_clock_next <= '1'; -- FLAG CAPTURE
                        ctrl_next <= "01";
                else
                        port_controller_clock_next <= '0';
                        ctrl_next <= "00";
                end if;

            when SOURCE_ADDRESS =>
                src_addr_next <= src_addr_next(07 downto 0) & S_AXIS_T_DATA;

                if(ctrl_reg = "00") then
                    ctrl_next <= "01";
                else
                    ctrl_next <= "00";
                end if;

            when DESTINATION_ADDRESS =>
                dest_addr_next <= dest_addr_next(07 downto 0) & S_AXIS_T_DATA;

                if(ctrl_reg = "00") then
                        port_controller_clock_next <= '1';  -- SOURCE ADDRESS CAPTURE
                        ctrl_next <= "01";
                else
                        port_controller_clock_next <= '0';
                        ctrl_next <= "00";
                end if;

            when PAYLOAD  =>
                port_controller_clock_next <= '1';  -- DESTINATION ADDRESS CAPTURE

            when FINISHED =>
                port_controller_clock_next <= '1';
                packet_length_next <= packet_length_next(07 downto 0) & S_AXIS_T_DATA;
                ctrl_next                       <= "01";
                seq_num_next                    <= (others => '0');
                src_addr_next                   <= (others => '0');
                dest_addr_next                  <= (others => '0');
                checksum_next                   <= (others => '0');
                flag_next                       <= (others => '0');

            when others =>
        end case;
    end process;

    o_port_controller_clock <= port_controller_clock_reg;
    o_seq_num               <= seq_num_reg;
    o_flag                  <= flag_reg;
    o_src_addr              <= src_addr_reg;
    o_dest_addr             <= dest_addr_reg;                        
    o_packet_length         <= packet_length_reg;
    o_checksum              <= checksum_reg;

end behavioral;
