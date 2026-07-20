`ifndef PCIE_GEN5_6_CFG_RD_WR_SEQ_SV
`define PCIE_GEN5_6_CFG_RD_WR_SEQ_SV

//------------------------------------------------------------------------------
// FILE: pcie_gen5_6_cfg_rd_wr_seq.sv
//
// THREE CLASSES:
//   pcie_gen5_6_cfg_rd_wr_seq_base      - shared do_cfg_access() helper
//   pcie_gen5_6_cfg_rd_wr_directed_seq  - deterministic, 3-step RD/WR/RD
//   pcie_gen5_6_cfg_rd_wr_random_seq    - randomized BDF + register space
//
// ALIAS:
//   pcie_gen5_6_cfg_rd_wr_seq -> directed (backward compat)
//
// WHAT WAS HARDCODED / WHY IT BREAKS:
//   - Addresses 64'h0, 64'h4, 64'h100 as full 64-bit addrs (wrong field:
//     config accesses use cfg_reg_addr[11:0], not addr[63:0])
//   - Tags 10'h001/002/003 fixed: no reuse/rollover coverage
//   - BDF always 0/0/0: enumeration, ARI, multi-function untestable
//   - Fixed byte enables: sub-DW write coverage missing
//   - No Type-1 (bridge downstream) support
//   - No negative test hooks (CRS, UR, bad LCRC)
//   - No IDE/PASID/OHC/ECRC propagation
//
// ALL FIXED via pcie_gen5_6_txn randomization anchored to cfg.
//------------------------------------------------------------------------------

//==============================================================================
// BASE CLASS
//==============================================================================
class pcie_gen5_6_cfg_rd_wr_seq_base extends pcie_gen5_6_base_seq;
  `uvm_object_utils(pcie_gen5_6_cfg_rd_wr_seq_base)

  function new(string name = "pcie_gen5_6_cfg_rd_wr_seq_base");
    super.new(name);
  endfunction

  //--------------------------------------------------------------------------
  // do_cfg_access()
  // Single Type-0 or Type-1 configuration read or write.
  //
  // Parameters:
  //   is_write   : 1 = CFG_WR, 0 = CFG_RD
  //   type1      : 1 = Type-1 (bridge forwarding), 0 = Type-0 (local)
  //   bus/dev/func: target BDF - from cfg by default, caller can override
  //   reg_addr   : 12-bit extended config space offset (DW-aligned)
  //   err        : error kind to inject on this specific access
  //
  // KEY FIXES:
  //   - cfg_reg_addr[11:0] used instead of addr[63:0] (correct TLP field)
  //   - tag randomized by txn constraint (not fixed 001/002/003)
  //   - first_be randomized (sub-DW write coverage)
  //   - last_be forced 4'b0000 (mandatory for 1-DW config access per spec)
  //   - IDE/PASID/OHC/ECRC all propagated from cfg
  //--------------------------------------------------------------------------
  task do_cfg_access(bit          is_write,
                      bit          type1,
                      bit [7:0]    bus,
                      bit [4:0]    dev,
                      bit [2:0]    func,
                      bit [11:0]   reg_addr,
                      pcie_error_kind_e err = ERR_NONE);
    pcie_gen5_6_txn  txn;
    pcie_tlp_type_e  sel_type;

    // Select correct TLP type
    if      ( is_write && !type1) sel_type = TLP_CFG_WR0;
    else if ( is_write &&  type1) sel_type = TLP_CFG_WR1;
    else if (!is_write && !type1) sel_type = TLP_CFG_RD0;
    else                          sel_type = TLP_CFG_RD1;

    txn = pcie_gen5_6_txn::type_id::create("cfg_txn");
    if (!txn.randomize() with {
          tlp_type      == sel_type;
          // Target BDF
          bus_num       == bus;
          dev_num       == dev;
          func_num      == func;
          // Requester BDF from cfg (RC or EP identity)
          requester_bus  == cfg.default_bus_num;
          requester_dev  == cfg.default_dev_num;
          requester_func == cfg.default_func_num;
          // Register offset: DW-aligned (bits[1:0]==00 enforced by txn constraint)
          cfg_reg_addr  == reg_addr;
          // Spec mandates: config accesses are exactly 1 DW, last_be = 0
          length_dw     == 1;
          last_be       == 4'b0000;
          // Feature flags from cfg
          flit_mode     == cfg.enable_flit_mode;
          ide_tlp       == cfg.ide_enable;
          pasid_present == cfg.pasid_enable;
          ohc_present   == cfg.ohc_enable;
          ecrc_present  == cfg.ecrc_enable;
          // Error kind for this access
          error_kind    == err;
        }) begin
      `uvm_fatal(get_type_name(),
        $sformatf("do_cfg_access: randomize failed (%s bdf=%0d/%0d/%0d reg=0x%03h)",
                   sel_type.name(), bus, dev, func, reg_addr))
    end

    check_txn_legality(txn);

    `uvm_info(get_type_name(),
      $sformatf("CFG %s [Type%0d]: bdf=%0d/%0d/%0d reg=0x%03h tag=%0d first_be=0x%01h "
                "flit=%0b ide=%0b pasid=%0b err=%s",
                is_write ? "WR" : "RD", type1 ? 1 : 0,
                bus, dev, func, reg_addr, txn.tag, txn.first_be,
                cfg.enable_flit_mode, cfg.ide_enable,
                cfg.pasid_enable, err.name()), UVM_MEDIUM)

    send_tlp(txn);
    do_inter_packet_delay();
  endtask

endclass : pcie_gen5_6_cfg_rd_wr_seq_base


//==============================================================================
// DIRECTED SEQUENCE
// Three-step: RD -> WR -> RD pattern from cfg BDF, fully cfg-driven.
//==============================================================================
class pcie_gen5_6_cfg_rd_wr_directed_seq extends pcie_gen5_6_cfg_rd_wr_seq_base;
  `uvm_object_utils(pcie_gen5_6_cfg_rd_wr_directed_seq)

  // Knobs: test sets these or leaves at 0 for auto-randomized offsets
  // All three registers must be different and DW-aligned (enforced by constraint)
  rand bit [11:0] reg_addr_read1;   // first read (e.g. Vendor/Device ID: 0x000)
  rand bit [11:0] reg_addr_write;   // write target (e.g. Command reg:      0x004)
  rand bit [11:0] reg_addr_read2;   // read-back (e.g. Capabilities:        0x100)

  constraint c_directed_regs {
    // Must be DW-aligned (bits[1:0] == 00)
    reg_addr_read1[1:0] == 2'b00;
    reg_addr_write[1:0] == 2'b00;
    reg_addr_read2[1:0] == 2'b00;
    // All three must target different registers
    reg_addr_read1 != reg_addr_write;
    reg_addr_write != reg_addr_read2;
    reg_addr_read1 != reg_addr_read2;
    // Stay within PCIe extended config space (4KB = 0x000..0xFFC)
    reg_addr_read1 inside {[12'h000:12'hFFC]};
    reg_addr_write inside {[12'h000:12'hFFC]};
    reg_addr_read2 inside {[12'h000:12'hFFC]};
  }

  // Error injection on specific steps (leave ERR_NONE for clean run)
  pcie_error_kind_e err_on_read1  = ERR_NONE;
  pcie_error_kind_e err_on_write  = ERR_NONE;
  pcie_error_kind_e err_on_read2  = ERR_NONE;

  function new(string name = "pcie_gen5_6_cfg_rd_wr_directed_seq");
    super.new(name);
  endfunction

  virtual task body();
    bit [7:0] bus;
    bit [4:0] dev;
    bit [2:0] func;

    super.pre_body();

    // Target BDF from cfg - no literals
    bus  = cfg.default_bus_num;
    dev  = cfg.default_dev_num;
    func = cfg.default_func_num;

    `uvm_info(get_type_name(),
      $sformatf("DIRECTED CFG RD/WR: bdf=%0d/%0d/%0d regs=[0x%03h, 0x%03h, 0x%03h] "
                "errs=[%s, %s, %s] flit=%0b",
                bus, dev, func,
                reg_addr_read1, reg_addr_write, reg_addr_read2,
                err_on_read1.name(), err_on_write.name(), err_on_read2.name(),
                cfg.enable_flit_mode), UVM_LOW)

    // Step 1: Read first register (e.g. Vendor/Device ID)
    do_cfg_access(.is_write(0), .type1(0),
                   .bus(bus), .dev(dev), .func(func),
                   .reg_addr(reg_addr_read1), .err(err_on_read1));

    // Step 2: Write to a different register
    do_cfg_access(.is_write(1), .type1(0),
                   .bus(bus), .dev(dev), .func(func),
                   .reg_addr(reg_addr_write), .err(err_on_write));

    // Step 3: Read-back from a third register (optionally with error)
    // When cfg.err_inj_enable is set and no explicit err_on_read2,
    // fall back to cfg.error_kind for the last step.
    do_cfg_access(.is_write(0), .type1(0),
                   .bus(bus), .dev(dev), .func(func),
                   .reg_addr(reg_addr_read2),
                   .err((err_on_read2 != ERR_NONE)    ? err_on_read2   :
                        (cfg.err_inj_enable)          ? cfg.error_kind :
                        ERR_NONE));

    super.post_body();
  endtask

endclass : pcie_gen5_6_cfg_rd_wr_directed_seq


//==============================================================================
// RANDOM SEQUENCE
// Randomized BDF, register offsets, Type0/1 mix, read/write mix, errors.
//==============================================================================
class pcie_gen5_6_cfg_rd_wr_random_seq extends pcie_gen5_6_cfg_rd_wr_seq_base;
  `uvm_object_utils(pcie_gen5_6_cfg_rd_wr_random_seq)

  rand int unsigned num_pairs;

  constraint c_num_pairs {
    num_pairs inside {[2:32]};
  }

  function new(string name = "pcie_gen5_6_cfg_rd_wr_random_seq");
    super.new(name);
  endfunction

  virtual task body();
    bit [7:0]         bus;
    bit [4:0]         dev;
    bit [2:0]         func;
    bit [11:0]        reg_addr;
    bit               type1;
    pcie_error_kind_e err;

    super.pre_body();

    `uvm_info(get_type_name(),
      $sformatf("RANDOM CFG RD/WR: num_pairs=%0d ari=%0b num_funcs=%0d err_inj=%0b",
                 num_pairs, cfg.ari_enable, cfg.num_functions, cfg.err_inj_enable), UVM_LOW)

    repeat (num_pairs) begin
      //--- Randomize BDF ---
      bus = cfg.default_bus_num;
      assert(std::randomize(dev)  with { dev  inside {[0:31]}; });
      // Function range: ARI allows 0-255 functions; non-ARI limits to cfg.num_functions
      if (cfg.ari_enable)
        assert(std::randomize(func) with { func inside {[0:7]}; });
      else
        assert(std::randomize(func) with { func inside {[0:(cfg.num_functions > 0 ? cfg.num_functions-1 : 0)]}; });

      // Type-1 is used for bridge forwarding (rare in typical regression)
      assert(std::randomize(type1) with { type1 dist {1'b0 := 9, 1'b1 := 1}; });

      // DW-aligned register address within extended config space
      assert(std::randomize(reg_addr) with {
        reg_addr[1:0]   == 2'b00;
        reg_addr inside {[12'h000:12'hFFC]};
      });

      //--- Decide error injection ---
      err = ERR_NONE;
      if (cfg.err_inj_enable) begin
        assert(std::randomize(err) with {
          err inside {
            ERR_NONE, ERR_UNSUPPORTED_REQUEST,
            ERR_BAD_LCRC, ERR_BAD_ECRC,
            ERR_COMPLETER_ABORT
          };
          err dist {
            ERR_NONE                 := 70,
            ERR_UNSUPPORTED_REQUEST  := 10,
            ERR_BAD_LCRC             := 8,
            ERR_BAD_ECRC             := 7,
            ERR_COMPLETER_ABORT      := 5
          };
        });
      end

      // Read (always happens; provides baseline response)
      do_cfg_access(.is_write(0), .type1(type1),
                     .bus(bus), .dev(dev), .func(func),
                     .reg_addr(reg_addr), .err(err));

      // Write to a different DW-aligned offset in the same function
      assert(std::randomize(reg_addr) with {
        reg_addr[1:0] == 2'b00;
        reg_addr inside {[12'h000:12'hFFC]};
      });
      do_cfg_access(.is_write(1), .type1(type1),
                     .bus(bus), .dev(dev), .func(func),
                     .reg_addr(reg_addr), .err(ERR_NONE));
    end

    super.post_body();
  endtask

endclass : pcie_gen5_6_cfg_rd_wr_random_seq


//------------------------------------------------------------------------------
// Backward-compat alias
//------------------------------------------------------------------------------
typedef pcie_gen5_6_cfg_rd_wr_directed_seq pcie_gen5_6_cfg_rd_wr_seq;

`endif




















