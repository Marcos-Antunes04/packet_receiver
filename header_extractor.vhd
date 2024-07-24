library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity header_extracter is
    port(
        -- input ports
        i_clk, i_ready , i_valid, i_last : in std_logic;
        i_data : in std_logic_vector(7 downto 0);
        -- output ports        
        o_packet_length : out std_logic_vector(15 downto 0);
        o_flag          : out std_logic_vector(7 downto 0);
        o_seq_num       : out std_logic_vector(31 downto 0);
        o_src_addr      : out std_logic_vector(15 downto 0);
        o_dest_addr     : out std_logic_vector(15 downto 0)
    );
end header_extracter;

architecture behavioral of header_extracter is
type state_type is (idle,pl_1, pl_2, sn_1, sn_2, sn_3, sn_4, flag, protocol, dummy_1, dummy_2, sa_1, sa_2, da_1, da_2, payload, finished);
signal state_reg  : state_type := pl_1;
signal state_next  : state_type;
signal packet_length : std_logic_vector(15 downto 0) := (others => '0');
signal seq_num : std_logic_vector(31 downto 0)       := (others => '0');
signal src_addr : std_logic_vector(15 downto 0)      := (others => '0');
signal dest_addr : std_logic_vector(15 downto 0)     := (others => '0');
begin

    -- atualização de estado
    process(i_clk,i_last)
    begin
        if(i_ready = '0' or i_valid = '0') then
            state_reg <= idle;
        elsif(i_last = '1') then
            state_reg <= finished;
        elsif(rising_edge(i_clk)) then
            state_reg <= state_next;
        elsif(falling_edge(i_last)) then
            state_reg <= pl_1;
        end if;
    end process;

    -- lógica de próximo estado
    state_next <= pl_2     when state_reg = pl_1     else
                  sn_1     when state_reg = pl_2     else
                  sn_2     when state_reg = sn_1     else
                  sn_3     when state_reg = sn_2     else
                  sn_4     when state_reg = sn_3     else
                  flag     when state_reg = sn_4     else
                  protocol when state_reg = flag     else
                  dummy_1  when state_reg = protocol else
                  dummy_2  when state_reg = dummy_1  else
                  sa_1     when state_reg = dummy_2  else
                  sa_2     when state_reg = sa_1     else
                  da_1     when state_reg = sa_2     else
                  da_2     when state_reg = da_1     else
                  payload  when state_reg = da_2     else
                  finished when state_reg = payload;
                  
    -- operações de estado
    process(state_reg)
    begin
        case(state_reg) is
            -- packet length
            when pl_1     =>
                packet_length(15 downto 8) <= i_data;
            when pl_2     =>
                packet_length(7 downto 0)  <= i_data;
                o_packet_length <= packet_length;

            -- sequence number
            when sn_1     =>
                seq_num(31 downto 24)      <= i_data;
            when sn_2     =>
                seq_num(23 downto 16)      <= i_data;
            when sn_3     =>
                seq_num(15 downto 8)       <= i_data;
            when sn_4     =>
                seq_num(7 downto 0)        <= i_data;
                o_seq_num <= seq_num;

            -- flag
            when flag     =>
                o_flag <= i_data;

            when protocol =>
            when dummy_1  =>
            when dummy_2  =>

            -- source address
            when sa_1     =>
                src_addr(15 downto 8) <= i_data;
            when sa_2     =>
                src_addr(7 downto 0)  <= i_data;
                o_src_addr <= src_addr;

            -- destination address
            when da_1     =>
                dest_addr(15 downto 8) <= i_data;
            when da_2     =>
                dest_addr(7 downto 0)  <= i_data;
                o_dest_addr <= dest_addr;
            when payload  =>
            when finished =>
            when others =>
        end case;

    end process;

end behavioral;
