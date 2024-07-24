ghdl --clean &&
ghdl -a checksum_rtl.vhd &&
ghdl -a checksum_tb.vhd && 
ghdl -e checksum_tb && 
ghdl -r checksum_tb --vcd=checksum_rtl.vcd --stop-time=40000ns && gtkwave checksum_rtl.vcd