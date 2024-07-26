library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity checksum is
    port(
        -- input ports
        i_clk, i_ready , i_valid, i_last : in std_logic;
        i_data : in std_logic_vector(7 downto 0);
        i_received_checksum : in std_logic_vector(15 downto 0);
        -- output ports
        o_calc_checksum : out std_logic_vector(15 downto 0);        
        o_flag : out std_logic
    );
end checksum;

architecture behavioral of checksum is
type state_type is (idle, msb, lsb, done_lsb, done_msb);
signal state_reg  : state_type := msb; -- por padrão o estado começa como least significant
signal state_next : state_type;
signal check_value_reg, check_value_next : std_logic_vector(31 downto 0) := (others => '0');
signal check_error_reg, check_error_next : std_logic := '0';
signal check_intermed_reg, check_intermed_next : std_logic_vector(7 downto 0) := (others=>'0');
signal check_calc_reg, check_calc_next : std_logic_vector(31 downto 0) := (others=>'0');
begin

    -- atualização de estado
    process(i_clk,i_last)
    begin
        if(i_ready = '0' or i_valid = '0') then -- valid e ready atuam como enable síncrono
            state_reg          <= idle              ;
            check_value_reg    <= check_value_reg   ;
            check_error_reg    <= check_error_reg   ;
            check_intermed_reg <= check_intermed_reg;
            check_calc_reg     <= check_calc_reg    ;
        elsif(rising_edge(i_clk)) then
            state_reg          <= state_next         ;
            check_value_reg    <= check_value_next   ;
            check_error_reg    <= check_error_next   ;
            check_intermed_reg <= check_intermed_next;
            check_calc_reg     <= check_calc_next    ;
        elsif(i_last = '1' and state_reg = lsb) then
            state_reg <= done_lsb;
            check_value_reg    <= check_value_next   ;
            check_error_reg    <= check_error_next   ;
            check_intermed_reg <= check_intermed_next;
            check_calc_reg    <= check_calc_next    ;
        elsif(i_last = '1' and state_reg = msb) then
            state_reg <= done_msb;
            check_value_reg    <= check_value_next   ;
            check_error_reg    <= check_error_next   ;
            check_intermed_reg <= check_intermed_next;
            check_calc_reg    <= check_calc_next    ;
        elsif(falling_edge(i_last)) then
            state_reg <= msb;
            check_value_reg    <= (others => '0');
            check_error_reg    <= '0';
            check_intermed_reg <= (others => '0');
            check_calc_reg     <= (others => '0');
        end if;
    end process;

    -- lógica de próximo estado
    state_next <= done_lsb  when i_last = '1' and state_reg = done_lsb                   else
                  done_msb  when i_last = '1' and state_reg = done_msb                   else
                  done_msb  when i_last = '1' and state_reg = idle and state_next = lsb  else
                  done_lsb  when i_last = '1' and state_reg = idle and state_next = msb  else
                  msb       when state_reg = lsb                                         else
                  lsb       when state_reg = msb                                         else
                  msb       when state_reg = done_lsb                                    else
                  msb       when state_reg = done_msb;
                  
    -- operações de estado
    process(state_reg,check_value_reg,check_intermed_reg,check_error_reg, i_data, i_received_checksum)
    begin
        -- default values
        check_intermed_next <= check_intermed_reg;
        check_error_next    <= check_error_reg;
        check_value_next    <= check_value_reg;
        check_calc_next     <= check_calc_reg;

        case(state_reg) is
            when msb =>
                check_intermed_next <= i_data;
            when lsb =>
                check_value_next <= std_logic_vector(unsigned(check_value_reg) + unsigned(check_intermed_reg & i_data));
                check_calc_next  <= std_logic_vector(unsigned(check_value_reg) + unsigned(check_intermed_reg & i_data) - unsigned(i_received_checksum));
                when done_msb =>
                check_calc_next <= std_logic_vector(unsigned(check_value_reg)  + unsigned(check_intermed_reg) - unsigned(i_received_checksum));
                check_value_next <= std_logic_vector(unsigned(check_value_reg) + unsigned(check_intermed_reg));
            when others =>
        end case;

        if((unsigned(check_value_reg) > X"FFFF") and (state_reg = done_msb or state_reg = done_lsb)) then
            check_value_next <= std_logic_vector(unsigned(X"0000" & check_value_reg(15 downto 0)) + unsigned(X"0000" & check_value_reg(31 downto 16)));
        end if;

        if((unsigned(check_calc_reg) > X"FFFF") and (state_reg = done_msb or state_reg = done_lsb)) then
            check_calc_next <= std_logic_vector(unsigned(X"0000" & check_calc_reg(15 downto 0)) + unsigned(X"0000" & check_calc_reg(31 downto 16)));
        end if;

        if(not(check_value_reg = X"0000ffff") and (state_reg = done_msb or state_reg = done_lsb)) then
            check_error_next <= '1';
        else

        check_error_next <= '0';
        end if;
        
        if(state_reg = done_msb or state_reg = done_lsb) then
            check_value_next <= (others => '0');
            check_calc_next <= not(check_calc_reg);
        end if;
    end process;

    o_flag <= check_error_next;
    o_calc_checksum <= check_calc_next(15 downto 0);

end behavioral;
