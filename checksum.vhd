library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity checksum is
    port(
        -- input ports
        i_clk               : in std_logic;
        S_AXIS_T_VALID      : in std_logic;
        S_AXIS_T_LAST       : in std_logic;
        S_AXIS_T_READY      : in std_logic;
        S_AXIS_T_DATA       : in std_logic_vector(7 downto 0);
        i_received_checksum : in std_logic_vector(15 downto 0);
        -- output ports
        o_calc_checksum     : out std_logic_vector(15 downto 0);        
        o_checksum_error    : out std_logic
    );
end checksum;

architecture behavioral of checksum is
type t_state_type is (EXEC, FINISHED);
signal state_reg         : t_state_type := EXEC; -- por padrão o estado começa como most significant
signal state_next        : t_state_type;

signal check_value_reg     : std_logic_vector(31 downto 0) := (others => '0');
signal check_value_next    : std_logic_vector(31 downto 0) := (others => '0');

signal check_error_reg     : std_logic := '0';
signal check_error_next    : std_logic := '0';

signal check_intermed_reg  : std_logic_vector(7 downto 0) := (others => '0');
signal check_intermed_next : std_logic_vector(7 downto 0) := (others => '0');

signal check_calc_reg      : std_logic_vector(31 downto 0) := (others => '0');
signal check_calc_next     : std_logic_vector(31 downto 0) := (others => '0');

signal ctrl_reg            : std_logic := '0';
signal ctrl_next           : std_logic := '0';

begin
    -- atualização de estado
    clk_process: process(i_clk)
    begin
        if(rising_edge(i_clk)) then
            state_reg        <= state_next       ;
            check_value_reg    <= check_value_next   ;
            check_error_reg    <= check_error_next   ;
            check_intermed_reg <= check_intermed_next;
            check_calc_reg     <= check_calc_next    ;
            ctrl_reg           <= ctrl_next          ;
        end if;
    end process;

    -- lógica de próximo estado
    next_state: process(state_reg, ctrl_reg, S_AXIS_T_VALID, S_AXIS_T_READY, S_AXIS_T_LAST)
    begin
        -- default value
        state_next <= state_reg;
        ctrl_next    <= ctrl_reg;

        case(state_reg) is
            when EXEC =>
                if S_AXIS_T_VALID = '1' and S_AXIS_T_READY = '1' then
                    ctrl_next <= not ctrl_reg;
                    if(S_AXIS_T_LAST = '1') then
                        state_next <= FINISHED;
                    end if;
                end if;

            when FINISHED =>
                if S_AXIS_T_VALID = '1' and S_AXIS_T_READY = '1'then
                        state_next <= EXEC;
                        ctrl_next <= '1';
                end if;

            when others =>
        end case;
    end process;


    
    datapath: process(state_reg,check_value_reg,check_intermed_reg, check_calc_reg, check_error_reg, ctrl_reg, S_AXIS_T_DATA, i_received_checksum, S_AXIS_T_LAST)
    begin
        -- default values
        check_error_next    <= check_error_reg;
        check_intermed_next <= check_intermed_reg;
        check_value_next    <= check_value_reg;
        check_calc_next     <= check_calc_reg;

        case(state_reg) is
            when EXEC =>
                if S_AXIS_T_VALID = '1' and S_AXIS_T_READY = '1' and ctrl_reg = '0' then
                    check_intermed_next <= S_AXIS_T_DATA;
                    if(S_AXIS_T_LAST = '1') then
                        check_calc_next <= std_logic_vector(unsigned(check_value_reg)  + unsigned(S_AXIS_T_DATA) - unsigned(i_received_checksum));
                        check_value_next <= std_logic_vector(unsigned(check_value_reg) + unsigned(S_AXIS_T_DATA));
                    end if;
                end if;

                if S_AXIS_T_VALID = '1' and S_AXIS_T_READY = '1' and ctrl_reg = '1' then
                    check_value_next <= std_logic_vector(unsigned(check_value_reg) + unsigned(check_intermed_reg & S_AXIS_T_DATA));
                    check_calc_next  <= std_logic_vector(unsigned(check_value_reg) + unsigned(check_intermed_reg & S_AXIS_T_DATA) - unsigned(i_received_checksum));
                end if;
            
            when FINISHED =>
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

                if(S_AXIS_T_LAST = '0') then
                    check_value_next    <= (others => '0');
                    check_error_next    <= '0';
                    check_intermed_next <= (others => '0');
                    check_calc_next     <= (others => '0');
                end if;               
            when others =>
        end case;
    end process;

    o_checksum_error <= check_error_next;
    o_calc_checksum <= check_calc_next(15 downto 0);

end behavioral;
