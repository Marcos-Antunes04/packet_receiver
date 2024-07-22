library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity checksum is
    port(
        -- input ports
        i_ready, i_valid, i_last : in std_logic;
        i_counter : in std_logic_vector(15 downto 0);
        i_data : in std_logic_vector(7 downto 0);
        -- output ports        
        o_flag : out std_logic
    );
end checksum;

architecture behavioral of checksum is
signal received_checksum : std_logic_vector(15 downto 0);
signal check_value : std_logic_vector(31 downto 0) := (others => '0');
signal check_error : std_logic := '0';
signal check_intermed : std_logic_vector(15 downto 0) := (others=>'0');
begin
                    
    process(i_counter, i_ready, i_valid, i_last)
    begin
        if(i_last = '0') then
            if((i_counter = X"0000") or (i_ready = '0') or (i_valid = '0')) then
                    check_intermed <= (others => '0');
                    received_checksum <= (others => '0');
                    check_value <= (others => '0');
                    check_error <= '0';
            elsif(i_counter(0) = '1') then -- valor ímpar
                    check_intermed <= X"00" & i_data;
            elsif(i_counter(0) = '0') then -- valor par
                    check_value <= std_logic_vector(unsigned(check_value) + unsigned(check_intermed(7 downto 0) & i_data));
                    check_intermed <= (others => '0');
            end if;

            if(to_integer(unsigned(i_counter)) = 3) then
                received_checksum <= X"00" & i_data;
            elsif(to_integer(unsigned(i_counter)) = 4) then
                received_checksum <= received_checksum(7 downto 0) & i_data;
            end if;

        else -- if i_last = '1'
            if(i_counter(0) = '1') then -- Se o counter terminar em valor ímpar
                check_value <= std_logic_vector(unsigned(check_value) + unsigned(check_intermed));
            end if;

            if(not(check_value = X"0000ffff")) then
                check_error <= '1';
            else
                check_error <= '0';
            end if;
        end if;
    end process;

    o_flag <= check_error;

end behavioral;
