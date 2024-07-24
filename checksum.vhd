library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity checksum is
    port(
        -- input ports
        i_clk, i_ready , i_valid, i_last : in std_logic;
        i_data : in std_logic_vector(7 downto 0);
        -- output ports        
        o_flag : out std_logic
    );
end checksum;

architecture behavioral of checksum is
type state_type is (idle, msb, lsb, done_lsb, done_msb);
signal state_reg  : state_type := lsb; -- por padrão o estado começa como par
signal state_next : state_type;
signal check_value : std_logic_vector(31 downto 0) := (others => '0');
signal check_error : std_logic := '0';
signal check_intermed : std_logic_vector(7 downto 0) := (others=>'0');
begin

    -- atualização de estado
    process(i_clk,i_last)
    begin
        if(i_ready = '0' or i_valid = '0') then
            state_reg <= idle;
        elsif(rising_edge(i_clk)) then
            state_reg <= state_next;
        elsif(i_last = '1' and state_reg = lsb) then
            state_reg <= done_lsb;
        elsif(i_last = '1' and state_reg = msb) then
            state_reg <= done_msb;
        end if;
    end process;

    -- lógica de próximo estado
    state_next <= done_lsb  when i_last = '1' and state_reg = done_lsb                   else
                  done_msb  when i_last = '1' and state_reg = done_msb                   else
                  done_msb  when i_last = '1' and state_reg = idle and state_next = lsb  else
                  done_lsb  when i_last = '1' and state_reg = idle and state_next = msb  else
                  msb       when state_reg = lsb                                       else
                  lsb       when state_reg = msb                                       else
                  msb       when state_reg = done_lsb                                  else
                  msb       when state_reg = done_msb;
                  
    -- operações de estado
    process(state_reg)
    begin
        case(state_reg) is
            when msb =>
                check_intermed <= i_data;
            when lsb =>
                check_value <= std_logic_vector(unsigned(check_value) + unsigned(check_intermed & i_data));
            when done_msb =>
                check_value <= std_logic_vector(unsigned(check_value) + unsigned(check_intermed));
            when others =>
        end case;

        if((unsigned(check_value) > X"FFFF") and (state_reg = done_msb or state_reg = done_lsb)) then
            check_value <= std_logic_vector(unsigned(X"0000" & check_value(15 downto 0)) + unsigned(X"0000" & check_value(31 downto 16)));
        end if;

        if(not(check_value = X"0000ffff") and (state_reg = done_msb or state_reg = done_lsb)) then
            check_error <= '1';
        else
            check_error <= '0';
        end if;
        
        if(state_reg = done_msb or state_reg = done_lsb) then
            check_value <= (others => '0');
        end if;
    end process;

    o_flag <= check_error;
end behavioral;
