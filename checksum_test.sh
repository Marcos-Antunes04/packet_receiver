ghdl --clean &&
ghdl -a checksum.vhd &&
ghdl -a checksum_tb.vhd && 
ghdl -e checksum_tb && 
ghdl -r checksum_tb --vcd=checksum.vcd --stop-time=40000ns && gtkwave checksum.vcd