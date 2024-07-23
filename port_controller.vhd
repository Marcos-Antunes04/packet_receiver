library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity port_controller is
    port(
        -- input ports
        i_ready, i_valid, i_last : in std_logic;
        i_counter : in std_logic_vector(15 downto 0);
        i_data : in std_logic_vector(7 downto 0);
        i_src_port, i_dest_port: in std_logic_vector(4 downto 0);
        -- output ports
        o_src_addr, o_dest_addr : out std_logic_vector(15 downto 0);
        -- portas de tratamento de erro, por padrão inicializadas com '0'
        seq_num_error : out std_logic    := '0';
        dest_addr_error : out std_logic  := '0';
        sync_error : out std_logic       := '0';
        close_error : out std_logic      := '0';
        sync_close_error : out std_logic := '0'
    );
end port_controller;

architecture behavioral of port_controller is
signal open_ports : std_logic_vector(4 downto 0)  := (others => '1'); -- por padrão, todas as portas são inicializadas livres
signal src_addr : std_logic_vector(15 downto 0)   := (others => '0');
signal dest_addr : std_logic_vector(15 downto 0)  := (others => '0');
signal received_seq_num : std_logic_vector(31 downto 0);
signal flag : std_logic_vector(7 downto 0);
signal intermed : std_logic_vector(7 downto 0);
signal state : std_logic_vector(1 downto 0) := "00"; -- sinal state é responsável por determinar se ocorrerá sincronização, fechamento ou apenas transmissão de pacote
type port_addr is array(4 downto 0) of std_logic_vector(15 downto 0); -- um array de endereços. cada endereço associado a uma porta
type seq_num is array(4 downto 0) of std_logic_vector(31 downto 0);   -- um array de seq_nums. cada seq_num associado a uma porta

begin
    process(i_counter, i_ready, i_valid, i_last) -- processo responsável por capturar os campos
    begin
        if(i_last = '0') then
            if((i_counter = X"0000") or (i_ready = '0') or (i_valid = '0')) then
                -- reseta as portas de endereço
                src_addr  <= (others => '0');
                dest_addr <= (others => '0');
                -- reseta as portas de erro
                seq_num_error    <= '0';
                dest_addr_error  <= '0';
                sync_error       <= '0';
                close_error      <= '0';
                sync_close_error <= '0';
                -- reseta o sinal de estado
                state <= "00";
            end if;

            case i_counter is
                -- captura do seq_num
                when X"0005" =>
                    received_seq_num(7 downto 0)   <= i_data;
                when X"0006" =>
                    received_seq_num(15 downto 8)  <= i_data;
                when X"0007" =>
                    received_seq_num(23 downto 16) <= i_data;
                when X"0008" =>
                    received_seq_num(31 downto 24) <= i_data;

                -- captura da flag
                when X"0009" =>
                    flag <= i_data;

                -- captura do src_addr
                when X"000D" =>
                    intermed  <= i_data;
                when X"000E" =>
                    src_addr  <= intermed & i_data;

                -- captura do dest_addr
                when X"000F" =>
                    intermed   <= i_data;
                when X"0010" =>
                    dest_addr  <= intermed & i_data;
                when others => 
            end case;
        end if;
    end process;

    process(flag)
    begin
        if(((flag(7) = '1') and (flag(0) = '1'))) then
            sync_close_error <= '1';
            state <= "00"; -- transmissão de pacote
        elsif(flag(7) = '1') then
            state <= "01"; -- mensagem de sincronização
        elsif(flag(0) = '1') then
            state <= "10"; -- mensagem de fechamento de conexão
        end if;
    end process;

    process(src_addr)  -- processo de veirificação do endereço de entrada
    begin
    
    if(flag = "01") then -- mensagem de sincronizaão
        if((unsigned(i_src_port) and unsigned(open_ports)) = 0) then
            sync_error <= '1';
        else
            open_ports <= open_ports and (not i_src_port);
        end if;
    end if;

    if(flag = "10") then -- mensagem de fechamento
        if((unsigned(i_src_port) and unsigned(open_ports)) /= 0) then
            close_error <= '1';
        else
            open_ports <= open_ports or i_src_port;
        end if;
    end if;
    end process;

    process(dest_addr) -- processo de veirificação do endereço de saída
    begin

    end process;


    o_src_addr <= src_addr;
    o_dest_addr <= dest_addr;
end behavioral;
