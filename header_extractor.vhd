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
        o_flag                  : out std_logic_vector(07 downto 0) := (others => '0');
        o_seq_num               : out std_logic_vector(31 downto 0) := (others => '0');
        o_src_addr              : out std_logic_vector(15 downto 0) := (others => '0');
        o_dest_addr             : out std_logic_vector(15 downto 0) := (others => '0');
        o_checksum              : out std_logic_vector(15 downto 0) := (others => '0');
        o_port_controller_clock : out std_logic
    );
end header_extractor;

architecture behavioral of header_extractor is
type state_type is (idle, packet_length_1, packet_length_2,checksum_1, checksum_2, seq_num_1, seq_num_2, seq_num_3, seq_num_4, flag, protocol, dummy_1, dummy_2, source_address_1, source_address_2, destination_address_1, destination_address_2, payload, finished); 
signal state_reg  : state_type := packet_length_1;
signal state_next : state_type;
signal packet_length_reg, packet_length_next : std_logic_vector(15 downto 0) := (others => '0');
signal seq_num_reg,seq_num_next              : std_logic_vector(31 downto 0) := (others => '0');
signal src_addr_reg, src_addr_next           : std_logic_vector(15 downto 0) := (others => '0');
signal dest_addr_reg, dest_addr_next         : std_logic_vector(15 downto 0) := (others => '0');
signal checksum_reg, checksum_next           : std_logic_vector(15 downto 0) := (others => '0');
signal flag_reg, flag_next                   : std_logic_vector(07 downto 0) := (others => '0');
signal port_controller_clock_reg,port_controller_clock_next : std_logic := '0';
begin

    -- atualização de estado
    process(i_clk,i_last)
    begin
        if(i_valid = '0') then -- sinais que funcionam como enable síncrono
            state_reg <= idle;
            packet_length_reg <= packet_length_reg;
            seq_num_reg       <= seq_num_reg;
            src_addr_reg      <= src_addr_reg;
            dest_addr_reg     <= dest_addr_reg;
            checksum_reg      <= checksum_reg;
            flag_reg          <= flag_reg;
            port_controller_clock_reg <= port_controller_clock_reg;
        elsif(i_last = '1') then
            state_reg <= finished;
            packet_length_reg <= packet_length_next;
            seq_num_reg       <= seq_num_next;
            src_addr_reg      <= src_addr_next;
            dest_addr_reg     <= dest_addr_next;
            checksum_reg      <= checksum_next;
            flag_reg          <= flag_next;
            port_controller_clock_reg <= port_controller_clock_next;
        elsif(rising_edge(i_clk)) then
            state_reg         <= state_next;
            packet_length_reg <= packet_length_next;
            seq_num_reg       <= seq_num_next;
            src_addr_reg      <= src_addr_next;
            dest_addr_reg     <= dest_addr_next;
            checksum_reg      <= checksum_next;
            flag_reg          <= flag_next;
            port_controller_clock_reg <= port_controller_clock_next;
        elsif(falling_edge(i_last)) then
            state_reg <= packet_length_1;
            packet_length_reg <= (others => '0');
            seq_num_reg       <= (others => '0');
            src_addr_reg      <= (others => '0');
            dest_addr_reg     <= (others => '0');
            checksum_reg      <= (others => '0');
            flag_reg          <= (others => '0');
            port_controller_clock_reg <= '0';
        end if;
    end process;

    -- lógica de próximo estado
    state_next <= packet_length_2       when state_reg = packet_length_1       else
                  checksum_1            when state_reg = packet_length_2       else
                  checksum_2            when state_reg = checksum_1            else 
                  seq_num_1             when state_reg = checksum_2            else
                  seq_num_2             when state_reg = seq_num_1             else
                  seq_num_3             when state_reg = seq_num_2             else
                  seq_num_4             when state_reg = seq_num_3             else
                  flag                  when state_reg = seq_num_4             else
                  protocol              when state_reg = flag                  else
                  dummy_1               when state_reg = protocol              else
                  dummy_2               when state_reg = dummy_1               else
                  source_address_1      when state_reg = dummy_2               else
                  source_address_2      when state_reg = source_address_1      else
                  destination_address_1 when state_reg = source_address_2      else
                  destination_address_2 when state_reg = destination_address_1 else
                  payload               when state_reg = destination_address_2;
                  
    -- operações de estado
    process(state_reg, packet_length_reg,checksum_reg,seq_num_reg,src_addr_reg,dest_addr_reg, flag_reg, i_data)
    begin
        -- dafault values
        packet_length_next <= packet_length_reg;
        checksum_next      <= checksum_reg;
        seq_num_next       <= seq_num_reg;
        src_addr_next      <= src_addr_reg;
        dest_addr_next     <= dest_addr_reg;
        flag_next          <= flag_reg;
        port_controller_clock_next <= port_controller_clock_reg;
        case(state_reg) is
            -- packet length
            when packet_length_1     =>
                port_controller_clock_next <= '0';
                packet_length_next(15 downto 8) <= i_data;
            when packet_length_2     =>
                packet_length_next(7 downto 0)  <= i_data;

            -- checksum
            when checksum_1     =>
                o_packet_length <= packet_length_reg;
                checksum_next(15 downto 8) <= i_data;
            when checksum_2     =>
                checksum_next(7 downto 0)  <= i_data;

            -- sequence number
            when seq_num_1     =>
                o_checksum <= checksum_reg;
                seq_num_next(31 downto 24) <= i_data;
            when seq_num_2     =>
                seq_num_next(23 downto 16) <= i_data;
            when seq_num_3     =>
                seq_num_next(15 downto 8)  <= i_data;
            when seq_num_4     =>
                seq_num_next(7 downto 0)   <= i_data;

            -- flag
            when flag     =>
                o_seq_num <= seq_num_reg;
                port_controller_clock_next <= '1';
                flag_next <= i_data;

            when protocol =>
                port_controller_clock_next <= '0';
                o_flag <= flag_reg;
            when dummy_1  =>
                port_controller_clock_next <= '1';
            when dummy_2  =>
                port_controller_clock_next <= '0';

            -- source address
            when source_address_1     =>
                src_addr_next(15 downto 8) <= i_data;
            when source_address_2     =>
                src_addr_next(7 downto 0)  <= i_data;

            -- destination address
            when destination_address_1     =>
                o_src_addr <= src_addr_reg;
                port_controller_clock_next <= '1';
                dest_addr_next(15 downto 8) <= i_data;
            when destination_address_2     =>
                port_controller_clock_next <= '0';
                dest_addr_next(7 downto 0)  <= i_data;

            -- payload
            when payload  =>
                o_dest_addr <= dest_addr_reg;
                port_controller_clock_next <= '1';
            
            -- finished state
            when finished =>
                o_dest_addr <= dest_addr_reg;
                port_controller_clock_next <= '1';

            -- eventually idle
            when others =>
        end case;

    end process;

    o_port_controller_clock <= port_controller_clock_reg;
end behavioral;
