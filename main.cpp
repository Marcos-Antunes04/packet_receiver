#include <iostream>
#include "stdint.h"
#include <vector>
#include <algorithm>

#define PAYLOAD_LENGTH 4*17


using namespace std;

bool valid = 0, ready = 0, clk = 0;
int freq;

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
    uint32_t checksum = 0;
    uint16_t ret_check;

    for(int i = 0; i < 15;){
        intermed[i] = (data[i+1] << 8) + data[i];
        i = i + 2;
    }
    
    for(int i = 0; i < 8; i++){
        checksum = checksum + intermed[i];
    }

    if(checksum > 0xffff){
        checksum = (checksum & 0xffff) + (checksum & 0xff0000 >> 16);
    }

    checksum = ~checksum;
    ret_check = (uint16_t) checksum;

    return ret_check;
}
/* Class declaration */
class slave{
    private:
    message data;
    vector<uint16_t> addr_table;
    public:
    void execution(uint8_t data_bus[16]); // receives data from data_bus
    void set_ready(bool value);
    void print_data(void);
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

    /*
    if(!(this->data.checksum == checksum_calculation(received_buffer))){
        cout << "VALOR INCOERENTE DE CHECKSUM";
        errors |= (1<<1);
    }
    */

    this->data.seq_num = received_buffer[4];
    this->data.seq_num = (this->data.seq_num << 8) | received_buffer[5];
    this->data.seq_num = (this->data.seq_num << 8) | received_buffer[6];
    this->data.seq_num = (this->data.seq_num << 8) | received_buffer[7];

    if(!(this->data.seq_num == prev_seq + 1)){
        cout << "VALOR INCOERENTE PARA NUMERO DE SEQUENCIA!\n";
        errors |= (1<<2);
    }

    this->data.flag = received_buffer[8];

    if((this->data.flag & 0x80) & ((this->data.flag & 0x01)))
        cout << "PROIBIDO!\n";

    this->data.protocol = received_buffer[9];

    this->data.dummy = received_buffer[10];
    this->data.dummy = (this->data.dummy << 8) | received_buffer[11];

    this->data.src_address = received_buffer[12];
    this->data.src_address = (this->data.src_address << 8) | received_buffer[13];

    if((this->data.flag & 0b10000000) & !contains(addr_table,this->data.src_address) & (addr_table.size() < 5))
        addr_table.push_back(this->data.src_address);                                       // Inclui esse valor de src_address na tabela
    if((this->data.flag & 0b00000001) & contains(addr_table,this->data.src_address))
        addr_table.erase(find(addr_table.begin(),addr_table.end(),this->data.src_address)); // Exclui esse valor de src_address da tabela


    this->data.dest_address = received_buffer[14];
    this->data.dest_address = (this->data.dest_address << 8) | received_buffer[15];

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

int main(void){
    slave slave_device;
    uint8_t data_1[16] = {0x00, 0x04, 0x7f, 0xe1, 0x00, 0x00, 0x00, 0x01, 0x80, 0x18, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00};

    slave_device.set_ready(1);
    slave_device.execution(data_1);
    slave_device.print_data();

    return 0;
}
