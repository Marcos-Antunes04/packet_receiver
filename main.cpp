#include <iostream>
#include "stdint.h"
#include <vector>
#include <algorithm>

#define PAYLOAD_LENGTH 4*17

using namespace std;

bool valid = 0, ready = 0, clk = 0;
int freq;
uint8_t data_bus;

uint8_t output_ports;
uint8_t errors;
uint8_t payload[PAYLOAD_LENGTH];

struct message{
    uint16_t packet_length, checksum, dummy, src_address, dest_address;
    uint32_t seq_num;
    uint8_t flag, protocol;
};

bool contains(const vector<uint16_t>& vec, uint16_t value) {
    return find(vec.begin(), vec.end(), value) != vec.end();
}

uint16_t checksum_calculation(uint8_t data[16]){
    uint16_t intermed[8];
    uint16_t checksum;
    
    for(int i = 0; i < 15;){
        intermed[i] = (data[i+1] << 8) + data[i];
        i = i + 2;
    }
    
    for(int i = 0; i < 8; i++){
        checksum = checksum + intermed[i];
    }

    checksum = ~checksum;

    return checksum;
}

class slave{
    private:
    message data;
    vector<uint16_t> addr_table;
    public:
    void execution(void); // receives data from data_bus
    void set_ready(bool value);
};

void slave::execution(void){
    uint8_t received_buffer[16];
    uint32_t prev_seq = this->data.seq_num;
    for(int i = 0; i < 32; i++){
        if(ready == 0)
            break;
        if(clk){
            clk = 0;
        }else{
            clk = 1;
            /* recebe dados do slave */
            if(ready == 0)
                break;
            received_buffer[i] = data_bus;
            
            /* enviar dados do payload */
        }
    }
    
    this->data.packet_length = received_buffer[15];
    this->data.packet_length = (this->data.packet_length << 8) | received_buffer[14];

    this->data.checksum = received_buffer[13];
    this->data.checksum = (this->data.checksum << 8) | received_buffer[12];

    if(!(this->data.checksum == checksum_calculation(received_buffer))){
        cout << "VALOR INCOERENTE DE CHECKSUM";
        errors |= (1<<1);
    }

    this->data.seq_num = received_buffer[11];
    this->data.seq_num = (this->data.seq_num << 8) | received_buffer[10];
    this->data.seq_num = (this->data.seq_num << 8) | received_buffer[9];
    this->data.seq_num = (this->data.seq_num << 8) | received_buffer[8];

    if(!(this->data.seq_num == prev_seq + 1)){
        cout << "VALOR INCOERENTE PARA NUMERO DE SEQUENCIA!\n";
        errors |= (1<<2);
    }

    this->data.flag = received_buffer[7];

    if(this->data.flag & 0b10000001)
        cout << "PROIBIDO!\n";

    this->data.protocol = received_buffer[6];

    this->data.dummy = received_buffer[5];
    this->data.dummy = (this->data.dummy << 8) | received_buffer[4];

    this->data.src_address = received_buffer[3];
    this->data.src_address = (this->data.src_address << 8) | received_buffer[2];

    if((this->data.flag & 0b10000000) & !contains(addr_table,this->data.src_address) & (addr_table.size() < 5))
        addr_table.push_back(this->data.src_address);                                       // Inclui esse valor de src_address na tabela
    if((this->data.flag & 0b00000001) & contains(addr_table,this->data.src_address))
        addr_table.erase(find(addr_table.begin(),addr_table.end(),this->data.src_address)); // Exclui esse valor de src_address da tabela


    this->data.dest_address = received_buffer[1];
    this->data.dest_address = (this->data.dest_address << 8) | received_buffer[0];


}


void slave::set_ready(bool value){
    if (value)
        ready = 1;
    else
        ready = 0;
}

int main(void){
    slave slave_device;

    while(1){
        cout << "Teste\n";
    }

    return 0;
}
