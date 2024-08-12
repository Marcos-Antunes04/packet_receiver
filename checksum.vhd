library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity checksum is
    port(
        -- input ports
        i_clk               : in std_logic;
        i_valid             : in std_logic;
        i_last              : in std_logic;
        i_ready             : in std_logic;
        i_data              : in std_logic_vector(7 downto 0);
        i_received_checksum : in std_logic_vector(15 downto 0);
        -- output ports
        o_calc_checksum     : out std_logic_vector(15 downto 0);        
        o_checksum_error    : out std_logic
    );
end checksum;

architecture behavioral of checksum is
type state_type is (EXEC, FINISHED);
signal r_STATE_REG         : state_type := EXEC; -- por padrão o estado começa como most significant
signal r_STATE_NEXT        : state_type;

signal CHECK_VALUE_REG     : std_logic_vector(31 downto 0) := (others => '0');
signal CHECK_VALUE_NEXT    : std_logic_vector(31 downto 0) := (others => '0');

signal CHECK_ERROR_REG     : std_logic := '0';
signal CHECK_ERROR_NEXT    : std_logic := '0';

signal CHECK_INTERMED_REG  : std_logic_vector(7 downto 0) := (others => '0');
signal CHECK_INTERMED_NEXT : std_logic_vector(7 downto 0) := (others => '0');

signal CHECK_CALC_REG      : std_logic_vector(31 downto 0) := (others => '0');
signal CHECK_CALC_NEXT     : std_logic_vector(31 downto 0) := (others => '0');

signal CTRL_REG            : std_logic := '0';
signal CTRL_NEXT           : std_logic := '0';

begin
    -- atualização de estado
    clk_process: process(i_clk)
    begin
        if(rising_edge(i_clk)) then
            r_STATE_REG        <= r_STATE_NEXT       ;
            CHECK_VALUE_REG    <= CHECK_VALUE_NEXT   ;
            CHECK_ERROR_REG    <= CHECK_ERROR_NEXT   ;
            CHECK_INTERMED_REG <= CHECK_INTERMED_NEXT;
            CHECK_CALC_REG     <= CHECK_CALC_NEXT    ;
            CTRL_REG           <= CTRL_NEXT          ;
        end if;
    end process;

    -- lógica de próximo estado
    next_state: process(r_STATE_REG, CTRL_REG, i_valid, i_ready, i_last)
    begin
        -- default value
        r_STATE_NEXT <= r_STATE_REG;
        CTRL_NEXT    <= CTRL_REG;

        case(r_STATE_REG) is
            when EXEC =>
                if i_valid = '1' and i_ready = '1' then
                    CTRL_NEXT <= not CTRL_REG;
                    if(i_last = '1') then
                        r_STATE_NEXT <= FINISHED;
                    end if;
                end if;

            when FINISHED =>
                if i_valid = '1' and i_ready = '1'then
                        r_STATE_NEXT <= EXEC;
                        CTRL_NEXT <= '1';
                end if;

            when others =>
        end case;
    end process;


    
    datapath: process(r_STATE_REG,CHECK_VALUE_REG,CHECK_INTERMED_REG, CHECK_CALC_REG, CHECK_ERROR_REG, CTRL_REG, i_data, i_received_checksum, i_last)
    begin
        -- default values
        CHECK_ERROR_NEXT    <= CHECK_ERROR_REG;
        CHECK_INTERMED_NEXT <= CHECK_INTERMED_REG;
        CHECK_VALUE_NEXT    <= CHECK_VALUE_REG;
        CHECK_CALC_NEXT     <= CHECK_CALC_REG;

        case(r_STATE_REG) is
            when EXEC =>
                if i_valid = '1' and i_ready = '1' and CTRL_REG = '0' then
                    CHECK_INTERMED_NEXT <= i_data;
                    if(i_last = '1') then
                        CHECK_CALC_NEXT <= std_logic_vector(unsigned(CHECK_VALUE_REG)  + unsigned(i_data) - unsigned(i_received_checksum));
                        CHECK_VALUE_NEXT <= std_logic_vector(unsigned(CHECK_VALUE_REG) + unsigned(i_data));
                    end if;
                end if;

                if i_valid = '1' and i_ready = '1' and CTRL_REG = '1' then
                    CHECK_VALUE_NEXT <= std_logic_vector(unsigned(CHECK_VALUE_REG) + unsigned(CHECK_INTERMED_REG & i_data));
                    CHECK_CALC_NEXT  <= std_logic_vector(unsigned(CHECK_VALUE_REG) + unsigned(CHECK_INTERMED_REG & i_data) - unsigned(i_received_checksum));
                end if;
            
            when FINISHED =>
                if((unsigned(CHECK_VALUE_REG) > X"FFFF")) then
                    CHECK_VALUE_NEXT <= std_logic_vector(unsigned(X"0000" & CHECK_VALUE_REG(15 downto 0)) + unsigned(X"0000" & CHECK_VALUE_REG(31 downto 16)));
                    if((unsigned(X"0000" & CHECK_VALUE_REG(15 downto 0)) + unsigned(X"0000" & CHECK_VALUE_REG(31 downto 16))) = X"0000FFFF") then
                        CHECK_ERROR_NEXT <= '0';
                    else
                        CHECK_ERROR_NEXT <= '1';
                    end if;
                else
                    if((unsigned(X"0000" & CHECK_VALUE_REG(15 downto 0))) = X"0000FFFF") then
                        CHECK_ERROR_NEXT <= '0';
                    else
                        CHECK_ERROR_NEXT <= '1';
                    end if;
                end if;

                if((unsigned(CHECK_CALC_REG) > X"FFFF")) then
                    CHECK_CALC_NEXT <= not(std_logic_vector(unsigned(X"0000" & CHECK_CALC_REG(15 downto 0)) + unsigned(X"0000" & CHECK_CALC_REG(31 downto 16))));
                else
                    CHECK_CALC_NEXT <= not(std_logic_vector(unsigned(CHECK_CALC_REG)));
                end if;

                if(i_last = '0') then
                    CHECK_VALUE_NEXT    <= (others => '0');
                    CHECK_ERROR_NEXT    <= '0';
                    CHECK_INTERMED_NEXT <= (others => '0');
                    CHECK_CALC_NEXT     <= (others => '0');
                end if;               
            when others =>
        end case;
    end process;

    o_checksum_error <= CHECK_ERROR_NEXT;
    o_calc_checksum <= CHECK_CALC_NEXT(15 downto 0);

end behavioral;
