library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity checksum_RTL is
    port(
        -- input ports
        i_clk, ready , valid, last : in std_logic;
        i_data : in std_logic_vector(7 downto 0);
        -- output ports        
        o_flag : out std_logic
    );
end checksum_RTL;

architecture behavioral of checksum_RTL is
type state_type is (idle, msb, lsb, done_lsb, done_msb);
signal state_reg  : state_type := lsb; -- por padrão o estado começa como par
signal state_next : state_type;
signal check_value : std_logic_vector(31 downto 0) := (others => '0');
signal check_error : std_logic := '0';
signal check_intermed : std_logic_vector(7 downto 0) := (others=>'0');
signal state : std_logic_vector(1 downto 0);
begin

    -- atualização de estado
    process(i_clk,last)
    begin
        if(ready = '0' or valid = '0') then
            state_reg <= idle;
        elsif(rising_edge(i_clk)) then
            state_reg <= state_next;
        elsif(last = '1' and state_reg = lsb) then
            state_reg <= done_lsb;
        elsif(last = '1' and state_reg = msb) then
            state_reg <= done_msb;
        end if;
    end process;

    -- lógica de próximo estado
    state_next <= --done_msb  when last = '1' and state_reg = msb                        else
                  --done_lsb  when last = '1' and state_reg = lsb                        else
                  done_lsb  when last = '1' and state_reg = done_lsb                   else
                  done_msb  when last = '1' and state_reg = done_msb                   else
                  done_msb  when last = '1' and state_reg = idle and state_next = lsb  else
                  done_lsb  when last = '1' and state_reg = idle and state_next = msb  else
                  msb       when state_reg = lsb                                       else
                  lsb       when state_reg = msb                                       else
                  msb       when state_reg = done_lsb                                  else
                  msb       when state_reg = done_msb;
                  
    -- operações de estado
    process(state_reg)
    begin
        if(state_reg = msb) then
            check_intermed <= i_data;
        elsif(state_reg = lsb) then
            check_value <= std_logic_vector(unsigned(check_value) + unsigned(check_intermed & i_data));
        elsif(state_reg = done_msb) then
            check_value <= std_logic_vector(unsigned(check_value) + unsigned(check_intermed));
        end if;

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
    state <= "00" when state_reg = lsb else
             "01" when state_reg = msb else
             "10" when state_reg = done_lsb else
             "11" when state_reg = done_msb;
             
end behavioral;
