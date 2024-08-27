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
type t_state_type is (IDLE, START, EXEC);
signal state_reg                        : t_state_type := IDLE; -- por padrão o estado começa como idle
signal state_next                       : t_state_type;

signal flags_reg                        : std_logic_vector(06 downto 0) := (others => '0');
signal flags_next                       : std_logic_vector(06 downto 0) := (others => '0');

signal calc_checksum_reg                : std_logic_vector(15 downto 0) := (others => '0');
signal calc_checksum_next               : std_logic_vector(15 downto 0) := (others => '0');

signal dest_addr_reg                    : std_logic_vector(15 downto 0) := (others => '0');
signal dest_addr_next                   : std_logic_vector(15 downto 0) := (others => '0');

signal seq_num_expected_reg             : std_logic_vector(31 downto 0) := (others => '0');
signal seq_num_expected_next            : std_logic_vector(31 downto 0) := (others => '0');

signal packet_length_reg                : std_logic_vector(15 downto 0) := (others => '0');
signal packet_length_next               : std_logic_vector(15 downto 0) := (others => '0');

signal ctrl_reg                         : std_logic_vector(03 downto 0) := (others => '0');
signal ctrl_next                        : std_logic_vector(03 downto 0) := (others => '0');

signal w_master_valid                   : std_logic := '0';
signal w_master_last                    : std_logic := '0';
signal w_master_data                    : std_logic_vector(07 downto 0) := (others => '0');

begin

    process(slave_i_clk)
    begin
        if(rising_edge(slave_i_clk)) then
            state_reg            <= state_next;
            flags_reg            <= flags_next;
            calc_checksum_reg    <= calc_checksum_next;
            dest_addr_reg        <= dest_addr_next;
            seq_num_expected_reg <= seq_num_expected_next;
            packet_length_reg    <= packet_length_next;
            ctrl_reg             <= ctrl_next;
        end if;
    end process;

    process(state_reg, ctrl_reg, flags_reg, S_AXIS_T_LAST, M_AXIS_TREADY)
    begin
        -- default value
        state_next <= state_reg;
        case state_reg is
            when IDLE =>
                if(S_AXIS_T_LAST = '1') then
                    state_next <= START;
                elsif(M_AXIS_TREADY = '1') then
                    state_next <= EXEC;
                end if;
            when START =>
                if(M_AXIS_TREADY = '1') then
                    state_next <= EXEC;
                else
                    state_next <= IDLE;
                end if;
            when EXEC =>
                if(S_AXIS_T_LAST = '1') then
                    state_next <= START;
                end if;

                if(M_AXIS_TREADY = '0') then
                    state_next <= IDLE;
                end if;

                case ctrl_reg is
                    when "0001" =>
                        if   (flags_reg(1) = '1') then 
                        elsif(flags_reg(2) = '1') then 
                        elsif(flags_reg(3) = '1') then
                        else
                            state_next <= IDLE;
                        end if; 
                    when "0011" =>
                        if   (flags_reg(2) = '1') then 
                        elsif(flags_reg(3) = '1') then
                        else
                            state_next <= IDLE;
                        end if; 
                    when "0111" =>
                        if   (flags_reg(3) = '1') then
                        else
                            state_next <= IDLE;
                        end if; 
                    when "1001" =>
                        state_next <= IDLE;
                    when others =>
                end case;
            when others =>
        end case;
    end process;

    process(state_reg,ctrl_reg, flags_reg, calc_checksum_reg, dest_addr_reg, seq_num_expected_reg, packet_length_reg, S_AXIS_T_LAST, i_flag, i_calc_checksum, i_dest_addr, i_seq_num_expected, i_packet_length_expected, M_AXIS_TREADY, slave_i_clk)
    begin
        -- Default values
        ctrl_next             <= ctrl_reg;
        
        case state_reg is
            when idle =>
                w_master_valid <= '0';
                w_master_last  <= '0';
                w_master_data  <= (others => '0');

                if   (flags_reg(0) = '1') then -- packet_length error
                    ctrl_next <= "0000";
                elsif(flags_reg(1) = '1') then -- checksum error
                    ctrl_next <= "0010";
                elsif(flags_reg(2) = '1') then -- seq_num error
                    ctrl_next <= "0100";
                elsif(flags_reg(3) = '1') then -- destination address not found
                    ctrl_next <= "1000";
                end if; 

            when START =>
                w_master_valid <= '0';
                w_master_last  <= '0';

                if   (flags_next(0) = '1') then -- packet_length error
                    ctrl_next <= "0000";
                elsif(flags_next(1) = '1') then -- checksum error
                    ctrl_next <= "0010";
                elsif(flags_next(2) = '1') then -- seq_num error
                    ctrl_next <= "0100";
                elsif(flags_next(3) = '1') then -- destination address not found
                    ctrl_next <= "1000";
                end if; 

                if(S_AXIS_T_LAST = '1') then
                    -- Esses sinais não podem receber atribuião padrão no início do process
                    flags_next            <= i_flag;
                    calc_checksum_next    <= i_calc_checksum;
                    dest_addr_next        <= i_dest_addr;
                    seq_num_expected_next <= i_seq_num_expected;
                    packet_length_next    <= i_packet_length_expected;

                    if(M_AXIS_TREADY = '1') then
                        w_master_valid <= '1';
                    end if;
                end if;

            when EXEC =>
                w_master_valid <= '1';
                w_master_last  <= '0';
                w_master_data  <= (others => '0');

                case ctrl_reg is
                    when "0000" => -- packet_length 1
                        if(M_AXIS_TREADY = '1') then
                            w_master_data <= packet_length_reg(15 downto 8);
                            ctrl_next <= "0001";
                        end if;
                    when "0001" => -- packet_length 2
                        if(M_AXIS_TREADY = '1') then
                            w_master_data <= packet_length_reg(07 downto 0);
                        end if;

                        if   (flags_reg(1) = '1') then -- checksum error
                            ctrl_next <= "0010";
                        elsif(flags_reg(2) = '1') then -- seq_num error
                            ctrl_next <= "0100";
                        elsif(flags_reg(3) = '1') then -- destination address not found
                            ctrl_next <= "1000";
                        else
                            w_master_last <= '1';
                            if(slave_i_clk = '0') then
                                w_master_valid <= '0';
                                w_master_last  <= '0';
                                w_master_data  <= (others => '0');
                            end if;
                        end if; 

                    when "0010" => -- checksum 1
                        if(M_AXIS_TREADY = '1') then
                            w_master_data <= calc_checksum_reg(15 downto 8);
                            ctrl_next <= "0011";
                        end if;
                    when "0011" => -- checksum 2
                        if(M_AXIS_TREADY = '1') then
                            w_master_data <= calc_checksum_reg(07 downto 0);
                        end if;

                        if   (flags_reg(2) = '1') then -- seq_num error
                            ctrl_next <= "0100";
                        elsif(flags_reg(3) = '1') then -- destination address not found
                            ctrl_next <= "1000";
                        else
                            w_master_last <= '1';
                            if(slave_i_clk = '0') then
                                w_master_valid <= '0';
                                w_master_last  <= '0';
                                w_master_data  <= (others => '0');
                            end if;
                        end if; 

                    when "0100" => -- seq_num 1
                        if(M_AXIS_TREADY = '1') then
                            w_master_data <= seq_num_expected_reg(31 downto 24);
                            ctrl_next <= "0101";
                        end if;
                    when "0101" => -- seq_num 2
                        if(M_AXIS_TREADY = '1') then
                            w_master_data <= seq_num_expected_reg(23 downto 16);
                            ctrl_next <= "0110";
                        end if;
                    when "0110" => -- seq_num 3
                        if(M_AXIS_TREADY = '1') then
                            w_master_data <= seq_num_expected_reg(15 downto 8);
                            ctrl_next <= "0111";
                        end if;
                    when "0111" => -- seq_num 4
                        if(M_AXIS_TREADY = '1') then
                            w_master_data <= seq_num_expected_reg(07 downto 0);
                        end if;

                        if(flags_reg(3) = '1') then -- destination address not found
                            ctrl_next <= "1000";
                        else
                            w_master_last <= '1';
                            if(slave_i_clk = '0') then
                                w_master_valid <= '0';
                                w_master_last  <= '0';
                                w_master_data  <= (others => '0');
                            end if;
                        end if; 

                    when "1000" => -- dest_addr 1
                        if(M_AXIS_TREADY = '1') then
                            w_master_data <= dest_addr_reg(15 downto 8);
                            ctrl_next <= "1001";
                        end if;
                    when "1001" => -- dest_addr 2
                        w_master_last <= '1';
                        if(M_AXIS_TREADY = '1') then
                            w_master_data <= dest_addr_reg(07 downto 0);
                        end if;
                        if(slave_i_clk = '0') then
                            w_master_valid <= '0';
                                w_master_last  <= '0';
                                w_master_data  <= (others => '0');
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
    M_AXIS_TDATA       <= w_master_data;

end behavioral;