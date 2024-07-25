ghdl --clean &&
ghdl -a header_extractor.vhd &&
ghdl -a header_extractor_tb.vhd && 
ghdl -e header_extractor_tb && 
ghdl -r header_extractor_tb --vcd=header_extractor.vcd --stop-time=40000ns && gtkwave header_extractor.vcd