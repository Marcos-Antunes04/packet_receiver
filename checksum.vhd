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
begin
                    
    process(i_counter)
    variable check_intermed : std_logic_vector(15 downto 0) := (others=>'0');

    begin
        case i_counter is
            when X"0000" =>
                check_intermed := (others => '0');
                check_value <= (others => '0');
            when X"0001" =>
                check_intermed := X"00" & i_data;
            when X"0002" =>
                check_intermed := check_intermed(7 downto 0) & i_data;
                check_value <= std_logic_vector(unsigned(check_value) + unsigned(check_intermed));
                check_intermed := (others => '0');
            when X"0003" =>
                received_checksum <= X"00" & i_data;
            when X"0004" =>
                received_checksum <= received_checksum(7 downto 0) & i_data;
            when X"0005" =>
                check_intermed := X"00" & i_data;
            when X"0006" =>
                check_intermed := check_intermed(7 downto 0) & i_data;
                check_value <= std_logic_vector(unsigned(check_value) + unsigned(check_intermed));
                check_intermed := (others => '0');

            when others => null;
        end case;
    end process;

end behavioral;
