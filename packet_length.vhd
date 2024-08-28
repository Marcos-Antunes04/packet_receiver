library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity packet_length is
    port(
        -- input ports
        i_clk                    : in std_logic;
        S_AXIS_T_VALID           : in std_logic;
        S_AXIS_T_LAST            : in std_logic;
        S_AXIS_T_READY           : in std_logic;
        i_received_packet_length : in std_logic_vector(15 downto 0);
        -- output ports
        o_packet_length_error    : out std_logic;
        o_calc_packet_length     : out std_logic_vector(15 downto 0)
    );
end packet_length;

architecture behavioral of packet_length is
type t_state_type is (COUNTING, FINISHED);
signal state_reg                : t_state_type := COUNTING; -- por padrão o estado começa como counting
signal state_next               : t_state_type;

signal counter_reg              : std_logic_vector(15 downto 0) := (others => '0');
signal counter_next             : std_logic_vector(15 downto 0) := (others => '0');

signal packet_length_error_reg  : std_logic := '0';
signal packet_length_error_next : std_logic := '0';

signal calc_packet_length_reg   : std_logic_vector(15 downto 0) := (others => '0'); 
signal calc_packet_length_next  : std_logic_vector(15 downto 0) := (others => '0'); 

begin

    state_machine: process(i_clk) 
    begin
        if(rising_edge(i_clk)) then
            state_reg               <= state_next;
            packet_length_error_reg <= packet_length_error_next;
            counter_reg             <= counter_next;
            calc_packet_length_reg  <= calc_packet_length_next; 
        end if;
    end process;
    
    next_state: process(state_reg, S_AXIS_T_LAST)
    begin
        -- default value
        state_next <= state_reg;

        case state_reg is
            when COUNTING =>
                if(S_AXIS_T_LAST = '1') then
                    state_next <= FINISHED;
                end if;
            when FINISHED =>
                state_next <= COUNTING;
            when others =>
        end case;
    end process;

    datapath: process(state_reg, counter_reg, packet_length_error_reg, calc_packet_length_reg, S_AXIS_T_READY, S_AXIS_T_VALID, S_AXIS_T_LAST)
    begin
        -- default values
        packet_length_error_next <= packet_length_error_reg;
        counter_next             <= counter_reg;
        calc_packet_length_next  <= calc_packet_length_reg;

        case state_reg is
            when COUNTING =>
                packet_length_error_next <= '0';
                if(S_AXIS_T_READY = '1' and S_AXIS_T_VALID = '1' and S_AXIS_T_LAST = '0') then
                    counter_next <= std_logic_vector(unsigned(counter_reg) + 1);
                end if;
            when FINISHED =>
                if (unsigned(counter_reg) = unsigned(4 * unsigned(i_received_packet_length)) - 1) then
                    packet_length_error_next <= '0';
                    calc_packet_length_next <= counter_reg;
                else
                    packet_length_error_next <= '1';
                    calc_packet_length_next <= counter_reg;
                end if;

                counter_next <= X"0001";
            when others =>
        end case;
    end process;

    o_packet_length_error <= packet_length_error_next;
    o_calc_packet_length  <= calc_packet_length_next;

end behavioral;
