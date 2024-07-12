#include <iostream>
#include "stdint.h"
#include <vector>
#include <algorithm>

using namespace std;

bool valid = 0, ready = 0, clk = 0;
int freq;

uint8_t output_ports;
uint8_t errors;     // Error vector

struct message{
    uint16_t packet_length, checksum, dummy, src_address, dest_address;
    uint32_t seq_num;
    uint8_t flag, protocol;
};

bool contains(const vector<uint16_t>& vec, uint16_t value) {
    return find(vec.begin(), vec.end(), value) != vec.end();
}

int index(const vector<uint16_t>& vec, uint16_t value) {
    return find(vec.begin(), vec.end(), value) - vec.begin();
}

/* Class declaration */
class slave{
    private:
    message data;
    uint16_t checksum_calculation(uint8_t data[16]);
    void flag_tester(void);
    public:
    vector<uint16_t> addr_table;
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

    if((this->data.flag & 0b10000000) & !contains(addr_table,this->data.src_address) & (addr_table.size() < 5))
        addr_table.push_back(this->data.src_address);                                       // Inclui esse valor de src_address na tabela
    if((this->data.flag & 0b00000001) & contains(addr_table,this->data.src_address))
        addr_table.erase(find(addr_table.begin(),addr_table.end(),this->data.src_address)); // Exclui esse valor de src_address da tabela

    //if((this->data.flag & 0b10000000) & addr_table.)

    this->data.dest_address = received_buffer[14];
    this->data.dest_address = (this->data.dest_address << 8) | received_buffer[15];

    if(!(this->data.checksum == this->checksum_calculation(received_buffer))){
        cout << "VALOR INCOERENTE DE CHECKSUM\n";
        errors |= (1<<1);
    }

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
    uint16_t checksum = 0;

    for (int i = 0; i < 8; i ++) {
        if (i == 1)
            continue;
        checksum += (data[2*i] << 8) + data[2*i + 1];
    }

    checksum = ~checksum;

    cout << "checksum function: "<< checksum << "\n";
    return (uint16_t) checksum;
}

void slave::flag_tester(void){
    if((this->data.flag & 0x80) & ((this->data.flag & 0x01)))
        cout << "PROIBIDO!\n";
}

void slave::print_table(void){
    cout << this->addr_table[1] << "\n";
}


int main(void){
    slave slave_device;
    uint8_t data_1[16] = {0x00, 0x04, 0x7f, 0xe1, 0x00, 0x00, 0x00, 0x01, 0x80, 0x18, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00};

    slave_device.set_ready(1);
    slave_device.execution(data_1);
    slave_device.print_data();
    slave_device.print_table();

    

    /*
    start()
    for()
        new_incoming_byte(uint8, start, end)
    end()
    */

    return 0;
}
