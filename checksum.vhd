library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity checksum is
    port(
        -- input ports
        i_clk, i_valid, i_last : in std_logic;
        o_ready : out std_logic;
        i_data : in std_logic_vector(7 downto 0);
        i_received_checksum : in std_logic_vector(15 downto 0);
        -- output ports
        o_calc_checksum : out std_logic_vector(15 downto 0);        
        o_checksum_error : out std_logic
    );
end checksum;

architecture behavioral of checksum is
type state_type is (idle, msb, lsb, done_lsb, done_msb);
signal state_reg  : state_type := msb; -- por padrão o estado começa como most significant
signal state_next : state_type;
signal check_value_reg, check_value_next : std_logic_vector(31 downto 0) := (others => '0');
signal check_error_reg, check_error_next : std_logic := '0';
signal check_intermed_reg, check_intermed_next : std_logic_vector(7 downto 0) := (others=>'0');
signal check_calc_reg, check_calc_next : std_logic_vector(31 downto 0) := (others=>'0');
signal estado : std_logic_vector (2 downto 0);
begin

    estado <= "000" when state_reg = idle else
              "001" when state_reg = msb else
              "010" when state_reg = lsb else
              "011" when state_reg = done_msb else
              "100" when state_reg = done_lsb;

    -- atualização de estado
    process(i_clk)
    begin
        if(i_valid = '0') then -- valid e ready atuam como enable síncrono
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

        end if;
    end process;

    
    -- lógica de próximo estado
    process(state_reg,i_last)
    begin
        case state_reg is
            when idle     =>
                if   (i_last = '1' and state_next = lsb) then
                    state_next <= done_msb;
                elsif(i_last = '1' and state_next = msb) then
                    state_next <= done_msb;
                end if;

            when done_lsb =>
                if(i_last = '1') then
                    state_next <= state_reg;
                else
                    state_next <= msb;
                end if;

            when done_msb =>
                if(i_last = '1') then
                    state_next <= state_reg;
                else
                    state_next <= msb;
                end if;

            when msb      =>
                if(i_last = '1') then
                    state_next <= done_msb;
                else
                    state_next <= lsb;
                end if;

            when lsb      =>
                if(i_last = '1') then
                    state_next <= done_lsb;
                else
                    state_next <= msb;
                end if;

            when others =>
        end case;
    end process;

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
                if((unsigned(check_value_reg) > X"FFFF")) then
                    check_value_next <= std_logic_vector(unsigned(X"0000" & check_value_reg(15 downto 0)) + unsigned(X"0000" & check_value_reg(31 downto 16)));
                    if((unsigned(X"0000" & check_value_reg(15 downto 0)) + unsigned(X"0000" & check_value_reg(31 downto 16))) = X"0000FFFF") then
                        check_error_next <= '0';
                    else
                        check_error_next <= '1';
                    end if;
                else
                    if((unsigned(X"0000" & check_value_reg(15 downto 0))) = X"0000FFFF") then
                        check_error_next <= '0';
                    else
                        check_error_next <= '1';
                    end if;
                end if;

                if((unsigned(check_calc_reg) > X"FFFF")) then
                    check_calc_next <= not(std_logic_vector(unsigned(X"0000" & check_calc_reg(15 downto 0)) + unsigned(X"0000" & check_calc_reg(31 downto 16))));
                else
                    check_calc_next <= not(std_logic_vector(unsigned(check_calc_reg)));
                end if;

            when done_lsb =>
                if((unsigned(check_value_reg) > X"FFFF")) then
                    check_value_next <= std_logic_vector(unsigned(X"0000" & check_value_reg(15 downto 0)) + unsigned(X"0000" & check_value_reg(31 downto 16)));
                    if((unsigned(X"0000" & check_value_reg(15 downto 0)) + unsigned(X"0000" & check_value_reg(31 downto 16))) = X"0000FFFF") then
                        check_error_next <= '0';
                    else
                        check_error_next <= '1';
                    end if;
                else
                    if((unsigned(X"0000" & check_value_reg(15 downto 0))) = X"0000FFFF") then
                        check_error_next <= '0';
                    else
                        check_error_next <= '1';
                    end if;
                end if;

                if((unsigned(check_calc_reg) > X"FFFF")) then
                    check_calc_next <= not(std_logic_vector(unsigned(X"0000" & check_calc_reg(15 downto 0)) + unsigned(X"0000" & check_calc_reg(31 downto 16))));
                else
                    check_calc_next <= not(std_logic_vector(unsigned(check_calc_reg)));
                end if;

            when others =>
        end case;
    end process;

    o_checksum_error <= check_error_next;
    o_calc_checksum <= check_calc_next(15 downto 0);

end behavioral;
