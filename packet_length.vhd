library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity packet_length is
    port(
        -- input ports
        i_clk                    : in std_logic;
        i_valid                  : in std_logic;
        i_last                   : in std_logic;
        i_ready                  : in std_logic;
        i_received_packet_length : in std_logic_vector(15 downto 0);
        -- output ports
        o_packet_length_error    : out std_logic
    );
end packet_length;

architecture behavioral of packet_length is
type state_type is (COUNTING, FINISHED);
signal r_STATE_REG              : state_type := COUNTING; -- por padrão o estado começa como counting
signal r_STATE_NEXT             : state_type;

signal COUNTER_REG              : std_logic_vector(15 downto 0) := (others => '0');
signal COUNTER_NEXT             : std_logic_vector(15 downto 0) := (others => '0');

signal PACKET_LENGTH_ERROR_REG  : std_logic := '0';
signal PACKET_LENGTH_ERROR_NEXT : std_logic := '0';

begin

    state_machine: process(i_clk) 
    begin
        if(rising_edge(i_clk)) then
            r_STATE_REG             <= r_STATE_NEXT;
            PACKET_LENGTH_ERROR_REG <= PACKET_LENGTH_ERROR_NEXT;
            COUNTER_REG             <= COUNTER_NEXT;
        end if;
    end process;
    
    next_state: process(r_STATE_REG, i_last)
    begin
        -- default value
        r_STATE_NEXT <= r_STATE_REG;

        case r_STATE_REG is
            when COUNTING =>
                if(i_last = '1') then
                    r_STATE_NEXT <= FINISHED;
                end if;
            when FINISHED =>
                r_STATE_NEXT <= COUNTING;
            when others =>
        end case;
    end process;

    datapath: process(r_STATE_REG, COUNTER_REG, PACKET_LENGTH_ERROR_REG, i_ready, i_valid, i_last)
    begin
        -- default values
        PACKET_LENGTH_ERROR_NEXT <= PACKET_LENGTH_ERROR_REG;
        COUNTER_NEXT             <= COUNTER_REG;

        case r_STATE_REG is
            when COUNTING =>
                PACKET_LENGTH_ERROR_NEXT <= '0';
                if(i_ready = '1' and i_valid = '1' and i_last = '0') then
                    COUNTER_NEXT <= std_logic_vector(unsigned(COUNTER_REG) + 1);
                end if;
            when FINISHED =>
                if (unsigned(COUNTER_REG) = unsigned(4 * unsigned(i_received_packet_length)) - 1) then
                    PACKET_LENGTH_ERROR_NEXT <= '0';
                else
                    PACKET_LENGTH_ERROR_NEXT <= '1';
                end if;

                COUNTER_NEXT <= X"0001";
            when others =>
        end case;
    end process;



    o_packet_length_error <= PACKET_LENGTH_ERROR_NEXT; 

end behavioral;
