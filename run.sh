ghdl -a *.vhd &&
#ghdl -a state_machine.vhd && 
#ghdl -a state_machine_testbench.vhd && 
ghdl -r tb_state_machine --fst=state_machine.fst --stop-time=40000ns && gtkwave state_machine.fst