ghdl -a checksum.vhd &&
ghdl -a state_machine.vhd && 
ghdl -a state_machine_testbench.vhd && 
ghdl -r tb_state_machine --vcd=state_machine.vcd --stop-time=40000ns && gtkwave state_machine.vcd