 TEST ?=pcie_gen5_6_flit_mode_test
 MODE ?= RC
 SPEED ?= 6
 WIDTH ?= 16
 ERROR ?= NONE

run:
	rm -rf xcelium.d INCA_libs
	xrun -sv \
	-uvm \
	-timescale 1ns/1ps \
	-f filelist.f \
	-access +rwc \
	-messages \
	-status \
	-l xrun.log \
	+UVM_TESTNAME=$(TEST) \
	+PCIE_MODE=$(MODE) \
	+PCIE_SPEED=$(SPEED) \
	+PCIE_WIDTH=$(WIDTH) \
	+PCIE_ERROR=$(ERROR)

# run:
#	xrun -sv -uvm
#	../tb/pkg/pcie_gen5_6_types_pkg.sv \
#  	../tb/interfaces/pcie_pipe_if.sv \
#  	../tb/interfaces/pcie_tl_if.sv \
#  	../tb/interfaces/pcie_dl_if.sv \
#  	../tb/pkg/pcie_gen5_6_pkg.sv \
#  	../rtl/pcie_gen5_6_dut_stub.sv \
#  	../tb/top/tb_top.sv \
#  	+UVM_TESTNAME=pcie_gen5_6_mem_rd_wr_directed_test \
#  	+UVM_VERBOSITY=UVM_LOW \
#  	-access +rw \
#  	-l sim.log
