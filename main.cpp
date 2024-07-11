#include <iostream>
#include "stdint.h"
#include "time.h"

using namespace std;

bool valid = 0, ready = 0, clk = 0;
int freq;
uint8_t data_bus;

struct message{
    uint16_t packet_length, checksum, dummy, src_address, dest_address;
    uint32_t seq_num;
    uint8_t flag, protocol;
};

class master{
    private:
    uint8_t data[16];
    int freq;
    
    public:
    void set_data(uint8_t data_in[16]);
    void execution(void); // transmits data to data_bus
};

class slave{
    private:
    message data;
    public:
    void execution(void); // receives data from data_bus
    void set_ready(bool value);
};

void master::set_data(uint8_t data_in[16]){
    for(int i = 0; i < 16; i++){
        this->data[i] = data_in[i];
    }
}

void master::execution(void){
    valid = 0;
    for(int i = 0; i < 16; i++){
        if(clk){
            clk = 0;
        }else{
            clk = 1;
            if(ready == 0)
                break;
            data_bus = this->data[i];
            /* enviar dados de payload */
        }
    }
    valid = 1;
}

void slave::execution(void){
    uint8_t received_buffer[16];
    for(int i = 0; i < 16; i++){
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

    this->data.checksum = received_buffer[11];
    this->data.seq_num = (this->data.seq_num << 8) | received_buffer[10];
    this->data.seq_num = (this->data.seq_num << 8) | received_buffer[9];
    this->data.seq_num = (this->data.seq_num << 8) | received_buffer[8];

    this->data.flag = received_buffer[7];

    this->data.protocol = received_buffer[6];

    this->data.dummy = received_buffer[5];
    this->data.dummy = (this->data.dummy << 8) | received_buffer[4];

    this->data.src_address = received_buffer[3];
    this->data.src_address = (this->data.src_address << 8) | received_buffer[2];

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
    master master_device;
    slave slave_device;

    // slave.set_ready
    // master.set_data

    while(1){
        cout << "Teste\n";
    }

    return 0;
}
