library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_state_machine is
-- Testbench não possui portas
end tb_state_machine;

architecture behavior of tb_state_machine is
    -- Sinal de clock e ready
    signal i_clk : std_logic := '0';
    signal i_ready : std_logic := '1';

    -- Instância do módulo a ser testado
    component state_machine
        port(
            i_clk : in std_logic;
            i_ready : in std_logic
        );
    end component;

begin
    -- Instanciar o módulo state_machine
    uut: state_machine
        port map (
            i_clk => i_clk,
            i_ready => i_ready
        );

    -- Gerador de clock
    clk_process : process
    begin
        while True loop
            i_clk <= '0';
            wait for 10 ns;
            i_clk <= '1';
            wait for 10 ns;
        end loop;
    end process;

    -- Processo de teste
    test_process : process
    begin
        -- Teste com o sinal de ready ativado
        i_ready <= '1';
        wait for 50 ns;

        -- Teste com o sinal de ready desativado
        i_ready <= '0';
        wait for 50 ns;

        -- Teste com o sinal de ready ativado novamente
        i_ready <= '1';
        wait for 50 ns;

        -- Encerrar a simulação após algum tempo
        wait;
    end process;

end behavior;
