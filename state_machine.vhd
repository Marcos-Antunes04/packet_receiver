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
    signal counter, next_counter : std_logic_vector(15 downto 0); -- tamanho máximo de pacote limitado
    alias payload_length_error : std_logic is o_flags(0);
    alias checksum_error : std_logic is o_flags(1);
    alias seq_num_error : std_logic is o_flags(2);
    alias dest_addr_not_found : std_logic is o_flags(3);
    alias synchronization : std_logic is o_flags(4);
    alias close : std_logic is o_flags(5);

    component checksum is
        port(
            i_ready, i_valid, i_last : in std_logic;
            i_counter : in std_logic_vector(15 downto 0);
            i_data : in std_logic_vector(7 downto 0);
            o_flag : out std_logic
        );
    end component;


begin
    
    u1: checksum
    port map(i_ready => i_ready, i_valid => i_valid, i_last => i_last, i_counter => counter, i_data => i_data, o_flag => checksum_error);

    process(i_clk, i_ready) -- valid funciona como clear assíncrono para a máquina
    begin
        if(i_ready = '0') then
            counter <= (others => '0');
        elsif(rising_edge(i_clk)) then -- verificar se é i_valid ou i_last
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
