library ieee;
use ieee.std_logic_1164.all;
entity even_testbench is
end even_testbench;

architecture arch of even_testbench is
    component even_detector
        port(
            a : in std_logic_vector(2 downto 0);
            even : out std_logic
        );
    end component;

    signal test_in : std_logic_vector(2 downto 0);
    signal test_out : std_logic;

begin
    -- Instancia o componente even_detector
    UUT: even_detector
        port map (
            a => test_in,
            even => test_out
        );

    -- Geração dos estímulos
    process
    begin
        test_in <= "000";
        wait for 200 ns;
        test_in <= "001";
        wait for 200 ns;
        test_in <= "010";
        wait for 200 ns;
        test_in <= "011";
        wait for 200 ns;
        test_in <= "100";
        wait for 200 ns;
        test_in <= "101";
        wait for 200 ns;
        test_in <= "110";
        wait for 200 ns;
        test_in <= "111";
        wait for 200 ns;
        wait;  -- Espera indefinidamente
    end process;

    -- Verificação dos resultados
    process
    variable error_status : boolean;
    begin
        while true loop
            wait until test_in'event;
            wait for 100 ns;

            if ((test_in = "000" and test_out = '1') or
                (test_in = "001" and test_out = '0') or
                (test_in = "010" and test_out = '0') or
                (test_in = "011" and test_out = '1') or
                (test_in = "100" and test_out = '0') or
                (test_in = "101" and test_out = '1') or
                (test_in = "110" and test_out = '1') or
                (test_in = "111" and test_out = '0')) then
                error_status := false;
            else
                error_status := true;
            end if;

            assert not error_status
                report "test failed"
                severity note;
        end loop;
    end process;

end arch;
