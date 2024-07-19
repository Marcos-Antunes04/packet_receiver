library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity state_machine is
    port(
        i_clk : in std_logic;
        i_ready : in std_logic
        --  Adicionar novas portas
    );
end state_machine;

architecture behavioral of state_machine is
    signal counter, next_counter : std_logic_vector(9 downto 0); -- tamanho máximo de 1023 bytes por pactore
begin
    process(i_clk, i_ready) -- ready funciona como clear assíncrono para a máquina
    begin
        if(i_ready = '0') then
            counter <= (others => '0');
        elsif(i_clk'event and i_clk = '1') then
            counter <= next_counter;
        end if;
    end process;
    
    next_counter <= (others => '0') when counter = 1023 else
                    counter + 1;
                    
    -- o primeiro valor de counter a ser amostrado será counter = 1
    process(counter) -- rotina de tratamento de estado
    begin

    end process;

end behavioral;
