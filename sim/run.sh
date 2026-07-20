run:
	xrun -sv \
	-timescale 1ns/1ps \
	-f filelist.f \
	-access +rwc \
	-input ./waves.tcl \
	+UVM_TESTNAME=$(TEST) \
	+PCIE_MODE=$(MODE) \
	+PCIE_SPEED=$(SPEED) \
	+PCIE_WIDTH=$(WIDTH) \
	+PCIE_ERROR=$(ERROR)














