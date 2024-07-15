#include <iostream>
#include "stdint.h"
#include <vector>
#include <string>

using namespace std;

uint8_t errors;     // Error vector
int ready = 0;

/* Struct definitions */
struct message{
    uint16_t packet_length, checksum, dummy, src_address, dest_address;
    uint32_t seq_num;
    uint8_t flag, protocol;
};

struct interface{
    string name;
    bool is_free = true; // Interface inicializada como limpa
    uint16_t address;
    uint32_t seq_num;
};

/* class Slave -- Representa o switch */
class slave{
    private:
    void checksum_calculation(uint8_t data, int index);
    void flag_tester(void);
    void sync_close(void);
    void seq_num_tester(void);
    message data;
    interface port[5];
    uint32_t counter = 0;
    uint32_t checksum = 0;
    uint8_t *payload;

    public:
    slave(void);
    void new_incoming_byte(uint8_t data_bus); // receives data from data_bus
    void start(void);
    void end(void);
    void print_data(void);
    void print_table(void);
};

/* Função responsável por realizar o desempacotamento dos campos do cabeçalho e executar rotinas de tratamento de erro */
void slave::new_incoming_byte(uint8_t data_bus){

    if(!ready)
        return;

    // Captura do packet lenght
    if(this->counter == 0){
        this->checksum = 0;
        cout << "Pacote recebido" << endl;
        this->data.packet_length = data_bus;
        this->data.packet_length = this->data.packet_length << 8;
    }
    if(this->counter == 1){
        this->data.packet_length |= data_bus;
        if(this->data.packet_length > 4){
            this->payload = new uint8_t [(this->data.packet_length - 4) * 4];
        }
    }

    // Captura do checksum
    if(this->counter == 2){
        this->data.checksum = data_bus;
        this->data.checksum = this->data.checksum << 8;
    }
    if(this->counter == 3){
        this->data.checksum |= data_bus;
    }

    // Captura do seq_num
    if(this->counter == 4){
        this->data.seq_num = data_bus;
        this->data.seq_num = this->data.seq_num << 8;
    }
    if(this->counter == 5){
        this->data.seq_num |= data_bus;
        this->data.seq_num = this->data.seq_num << 8;
    }
    if(this->counter == 6){
        this->data.seq_num |= data_bus;
        this->data.seq_num = this->data.seq_num << 8;
    }
    if(this->counter == 7){
        this->data.seq_num |= data_bus;
    }

    // Captura da flag
    if(this->counter == 8){
        this->data.flag = data_bus;
        this->flag_tester();    // Verifica se sync = 1 e close = 1
    }

    // Captura do protocol
    if(this->counter == 9){
        this->data.protocol = data_bus;
    }

    // Captura do dummy
    if(this->counter == 10){
        this->data.dummy = data_bus;
        this->data.dummy = this->data.dummy << 8;
    }
    if(this->counter == 11){
        this->data.dummy |= data_bus;
    }

    // Captura do src_address
    if(this->counter == 12){
        this->data.src_address = data_bus;
        this->data.src_address = this->data.src_address << 8;
    }
    if(this->counter == 13){
        this->data.src_address |= data_bus;
    }

    // Captura do dest_address
    if(this->counter == 14){
        this->data.dest_address = data_bus;
        this->data.dest_address = this->data.dest_address << 8;
    }
    if(this->counter == 15){
        this->data.dest_address |= data_bus;
        this->seq_num_tester(); // Verificador de seq_num
        this->sync_close(); // Atualiza a tabela de endereco fisico
    }
    if(this->counter > 15){
        this->payload[this->counter - 16] = data_bus;
        cout << this->payload[this->counter - 16] << endl;
    }

    this->checksum_calculation(data_bus,counter);
    this->counter++;
}

/* Inicia a comunicação */
void slave::start(void){
    ready = 1;
}

/* Termina a comunicação */
void slave::end(void){
    ready = 0;
    if(this->counter != (this->data.packet_length * 4)){
        cout << "Tamanho incoerente de pacote recebido" << endl;
    }
    this->counter = 0;
    if(this->data.packet_length > 4){
        delete this->payload;
    }
}

/* Printa individualmente os campos do cabeçalho do último pacote recebido */
void slave::print_data(void){
    cout << "packet length: " << this->data.packet_length << '\n';
    cout << "checksum: " << this->data.checksum << '\n';
    cout << "sequence number: " << this->data.seq_num << '\n';
    cout << "flag: " << static_cast<int>(this->data.flag) << '\n';
    cout << "protocol: " << static_cast<int>(this->data.protocol) << '\n';
    cout << "dummy: " << this->data.dummy << '\n';
    cout << "source address: " << this->data.src_address << '\n';
    cout << "destination address: " << this->data.dest_address << '\n';
}

/* Realiza o cálculo da checksum baseado no pacote recebido */
void slave::checksum_calculation(uint8_t data, int index){
    static uint32_t intermed = 0;

    if(((index % 2) == 0) & (index != 2)){
        intermed = data;
    }
    if(((index % 2) == 1) & (index != 3)){
        intermed = intermed << 8;
        intermed |= data;
        this->checksum += intermed;
        intermed = 0;
    }
    if((index > 14) & (index == (this->data.packet_length*4-1))){
        if(this->checksum > 0xffff){ // Tratamento de carry
            this->checksum = ((this->checksum & 0xffff) + ((this->checksum >> 16) & 0xffff));
        }

        this->checksum = (0xffff & ~this->checksum);

        // cout << "checksum function: "<< (uint16_t) this->checksum << "\n";
        if(this->data.checksum != (uint16_t) this->checksum)
            cout << "Valor incoerente de checksum" << endl;
    }
}

/* Verifica a existencia de erros no campo flag*/
void slave::flag_tester(void){
    if((this->data.flag & 0b10000001) == 0b10000001)
        cout << "Campo de flag indicando sincronizacao e fechamento -> proibido" << endl;
}

/* Trata mensagens de sincronização ou fechamento*/
void slave::sync_close(void){
    if((this->data.flag & 0b10000001) == 0b10000000){ // Mensagem de sincronização
        bool error_flag = false;
        for(int i = 0; i < 5; i++){
            if(this->port[i].address == this->data.src_address){
                cout << "Erro de sincronizacao. Endereço já definido na tabela" << endl;
                error_flag = true;
                break;
            }
        }

        if(error_flag == false){
            for(int i = 0; i < 5; i++){
                if(this->port[i].is_free == true){  // Verifica se a porta está livre
                    this->port[i].address = this->data.src_address;
                    this->port[i].is_free = false; // Seta a porta como ocupada
                    this->port[i].seq_num = this->data.seq_num;
                    cout << "Endereco armazenado em: " << this->port[i].name << endl;
                    break;
                }

                if((i == 4) & (this->port[i].is_free == false))
                    cout << "Todas as portas cheias" << endl;
            }
        }
    }

    if((this->data.flag & 0b10000001) == 0b00000001){ // Mensagem de fechamento 
        for(int i = 0; i < 5; i++){
            if(this->port[i].address == this->data.src_address){
                this->port[i].is_free = true;
                cout << "Fechamento de conexao: " << this->port[i].name << endl;
                break;
            }
            if((i == 4) & ((this->port[i].address != this->data.src_address)))
                cout << "Endereco nao esta contido na tabela. Nao ocorrera fechamento de porta" << endl;
        }
    }
}

/* Constroi a tabela de roteamento de endereços físicos */
void slave::print_table(void){
    for(int i = 0; i < 5; i++){
        if(this->port[i].is_free == false)
            break;
        if((i == 4) & (this->port[i].is_free == true)){
            cout << "Nao ha endereco armazenado na tabela" << endl;
            return ;
        }
    }

    cout << "| Tabela de Enderecos Fisicos |" << endl; 

    for(int i = 0; i < 5; i++){
        if(this->port[i].is_free == false){
            cout << "| " << this->port[i].name << " | " << this->port[i].address << " |" << endl;
        }
    }
}

/* Verifica se o valor de seq num recebido no pacote é coerente com o último valor de seq_num recebido em determinada porta */
void slave::seq_num_tester(void){
    for(int i = 0; i < 5; i++){
        if(this->port[i].address == this->data.src_address){
            if(this->data.seq_num != (this->port[i].seq_num + 1))
                cout << "Valor incoerente de seq num" << endl;
            else
                this->port[i].seq_num++;
            break;
        }
    }
}

slave::slave(void){     // Construtor
    this->port[0].name = "PORTA 0";
    this->port[1].name = "PORTA 1";
    this->port[2].name = "PORTA 2";
    this->port[3].name = "PORTA 3";
    this->port[4].name = "PORTA 4";
}

int main(void){
    slave slave_device;
    uint8_t data_1[16] = {0x00, 0x04, 0x7f, 0xe1, 0x00, 0x00, 0x00, 0x01, 0x80, 0x18, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00};
    uint8_t data_2[16] = {0x00, 0x04, 0x7f, 0xdc, 0x00, 0x00, 0x00, 0x05, 0x80, 0x18, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00};
    uint8_t data_3[28] = {0x00, 0x07, 0xad, 0xec, 0x00, 0x00, 0x00, 0x02, 0x00, 0x18, 0x00, 0x00, 0x00, 0x01, 0x00, 0x02, 0x48, 0x65, 0x6C, 0x6C, 0x6F, 0x20, 0x57, 0x6F, 0x72, 0x6C, 0x64, 0x21};
    uint8_t data_4[28] = {0x00, 0x07, 0x10, 0x86, 0x00, 0x00, 0x00, 0x06, 0x00, 0x18, 0x00, 0x00, 0x00, 0x02, 0x00, 0x01, 0x21, 0x64, 0x6C, 0x72, 0x6F, 0x57, 0x20, 0x6F, 0x6C, 0x6C, 0x65, 0x48};
    uint8_t data_5[16] = {0x00, 0x04, 0xfe, 0xdf, 0x00, 0x00, 0x00, 0x03, 0x01, 0x18, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00};
    uint8_t data_6[16] = {0x00, 0x04, 0xfe, 0xda, 0x00, 0x00, 0x00, 0x07, 0x01, 0x18, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00};
    
    slave_device.start();
    for(int i = 0; i < sizeof(data_1); i++)
        slave_device.new_incoming_byte(data_1[i]);
    slave_device.end();

    slave_device.start();
    for(int i = 0; i < sizeof(data_2); i++)
        slave_device.new_incoming_byte(data_2[i]);
    slave_device.end();

    slave_device.print_table();

    slave_device.start();
    for(int i = 0; i < sizeof(data_3); i++)
        slave_device.new_incoming_byte(data_3[i]);
    slave_device.end();

    slave_device.start();
    for(int i = 0; i < sizeof(data_5); i++)
        slave_device.new_incoming_byte(data_5[i]);
    slave_device.end();

    slave_device.print_table();

    return 0;
}   
