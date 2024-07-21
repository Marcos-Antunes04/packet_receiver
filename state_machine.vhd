library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity state_machine is
    port(
        -- input ports
        i_clk, i_ready, i_valid, i_last : in std_logic;
        i_data : in std_logic_vector(7 downto 0);
        i_src_port, i_dest_port: in std_logic_vector(4 downto 0);
        -- output ports        
        o_ready, o_valid, o_last : out std_logic; 
        o_data : out std_logic_vector(7 downto 0);
        o_src_addr, o_dest_addr : out std_logic_vector(15 downto 0);
        o_flags : out std_logic_vector(5 downto 0)
    );
end state_machine;

architecture behavioral of state_machine is
    signal counter, next_counter : std_logic_vector(9 downto 0); -- tamanho máximo de 1023 bytes por pactore
begin
    process(i_clk, i_ready) -- ready funciona como clear assíncrono para a máquina
    begin
        if(i_ready = '0') then
            counter <= (others => '0');
        elsif(rising_edge(i_clk)) then
            counter <= next_counter;
        end if;
    end process;
    
    next_counter <= (others => '0') when counter = "1111111111" else
                     std_logic_vector(unsigned(counter) + "0000000001");
                    
    -- o primeiro valor de counter a ser amostrado será counter = 1
    process(counter) -- rotina de tratamento de estado
    begin

    end process;

end behavioral;
