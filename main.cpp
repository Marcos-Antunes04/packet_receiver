#include <iostream>
#include "stdint.h"
#include <vector>
#include <algorithm>
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
};

/* Class declaration */
class slave{
    private:
    message data;
    interface port[5];
    uint16_t checksum_calculation(uint8_t data[16]);
    void flag_tester(void);
    void sync_close(void);

    public:
    slave(void);
    void execution(uint8_t data_bus[16]); // receives data from data_bus
    void set_ready(bool value);
    void print_data(void);
    void print_table(void);
};

void slave::execution(uint8_t data_bus[16]){
    uint8_t received_buffer[16];
    uint32_t prev_seq = this->data.seq_num;
    for(int i = 0; i < 16; i++){
            if(ready == 0)
                break;
            received_buffer[i] = data_bus[i];
    }
    
    this->data.packet_length = received_buffer[0];
    this->data.packet_length = (this->data.packet_length << 8) | received_buffer[1];

    this->data.checksum = received_buffer[2];
    this->data.checksum = (this->data.checksum << 8) | received_buffer[3];

    this->data.seq_num = received_buffer[4];
    this->data.seq_num = (this->data.seq_num << 8) | received_buffer[5];
    this->data.seq_num = (this->data.seq_num << 8) | received_buffer[6];
    this->data.seq_num = (this->data.seq_num << 8) | received_buffer[7];

    this->data.flag = received_buffer[8];

    flag_tester();

    this->data.protocol = received_buffer[9];

    this->data.dummy = received_buffer[10];
    this->data.dummy = (this->data.dummy << 8) | received_buffer[11];

    this->data.src_address = received_buffer[12];
    this->data.src_address = (this->data.src_address << 8) | received_buffer[13];

    this->data.dest_address = received_buffer[14];
    this->data.dest_address = (this->data.dest_address << 8) | received_buffer[15];

    if(!(this->data.checksum == this->checksum_calculation(received_buffer))){
        cout << "Valor incoerente de checksum!" << endl;
        errors |= (1<<1);
    }

    this->sync_close(); // Atualiza a tabela de endereco fisico
}

void slave::set_ready(bool value){
    if (value)
        ready = 1;
    else
        ready = 0;
}

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

uint16_t slave::checksum_calculation(uint8_t data[16]){
    uint32_t checksum = 0;

    for (int i = 0; i < 8; i ++) {
        if (i == 1)
            continue;
        checksum += (uint16_t) ((data[2*i] << 8) + data[2*i + 1]);
    }

    if(checksum > 0xffff){ // Tratamento de carry
        checksum = ((checksum & 0xffff) + ((checksum >> 16) & 0xffff));
    }

    checksum = (0xffff & ~checksum);

    cout << "checksum function: "<< checksum << "\n";
    return (uint16_t) checksum;
}

void slave::flag_tester(void){
    if((this->data.flag & 0b10000001) == 0b10000001)
        cout << "Campo de flag indicando sincronizacao e fechamento -> proibido" << endl;
}

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
            if(this->port[i].address == this->data.src_address)
                this->port[i].is_free == true;
            if((i == 4) & ((this->port[i].address != this->data.src_address)))
                cout << "Endereco nao esta contido na tabela. Nao ocorrera fechamento de porta" << endl;
        }

    }
}

void slave::print_table(void){
    for(int i = 0; i < 5; i++){
        if(this->port[i].is_free == false)
            break;
        if((i == 4) & (this->port->is_free == true)){
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

    slave_device.set_ready(1);
    slave_device.execution(data_1);

    // slave_device.print_table();
    

    /*
    start()
    for()
        new_incoming_byte(uint8, start, end)
    end()
    */

    return 0;
}
