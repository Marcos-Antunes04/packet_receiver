ghdl --clean &&
ghdl -a checksum.vhd &&
ghdl -a header_extractor.vhd && 
ghdl -a packet_length.vhd && 
ghdl -a top_module.vhd &&
ghdl -a top_module_tb.vhd &&
ghdl -r tb_top_module --vcd=top_module.vcd --stop-time=40000ns && gtkwave top_module.vcd