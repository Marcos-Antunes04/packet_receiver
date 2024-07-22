# Switch receiver project

## ghdl installation process
```sh
git clone https://github.com/ghdl/ghdl.git
cd ghdl
sudo apt install gnat
./configure --prefix=/usr/local
make
sudo make install
ghdl --version
```
## testbench simulation using gtkwave
```sh
ghdl -a state_machine.vhd
ghdl -a state_machine_testbench.vhd
ghdl -r tb_state_machine --vcd=state_machine.vcd
gtkwave state_machine.vcd
```
