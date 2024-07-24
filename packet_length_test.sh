ghdl --clean &&
ghdl -a packet_length.vhd &&
ghdl -a packet_length_tb.vhd && 
ghdl -e packet_length_tb && 
ghdl -r packet_length_tb --vcd=packet_length.vcd --stop-time=40000ns && gtkwave packet_length.vcd