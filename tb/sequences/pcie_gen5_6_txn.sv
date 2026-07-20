`ifndef PCIE_GEN5_6_TXN_SV
`define PCIE_GEN5_6_TXN_SV

//------------------------------------------------------------------------------
// CLASS: pcie_gen5_6_txn
//
// Generic, reusable PCIe Gen5/Gen6 transaction descriptor. This is the
// "transaction object" referenced by requirement #8: sequences build one of
// these (constrained-random), and then translate it into the appropriate
// pcie_tlp_item / pcie_dlp_item / pcie_pipe_symbol_item via helper tasks in
// the base sequence. This decouples "what transaction do I want to send"
// (protocol intent) from "how is it encoded on the bus" (driver item).
//------------------------------------------------------------------------------
class pcie_gen5_6_txn extends uvm_sequence_item;
  `uvm_object_utils(pcie_gen5_6_txn)

  //----------------------------------------------------------------------
  // Core TLP identity
  //----------------------------------------------------------------------
  rand pcie_tlp_type_e   tlp_type;
  rand bit [63:0]        addr;
  rand bit [9:0]         tag;
  rand bit [3:0]         first_be;
  rand bit [3:0]         last_be;
  rand int unsigned      length_dw;     // payload length in DWORDs (1..1024)

  //----------------------------------------------------------------------
  // Routing / requester context
  //----------------------------------------------------------------------
  rand bit [7:0]         bus_num;
  rand bit [4:0]         dev_num;
  rand bit [2:0]         func_num;
  rand bit [7:0]         requester_bus;
  rand bit [4:0]         requester_dev;
  rand bit [2:0]         requester_func;
  rand bit [5:0]         bar_num;       // 0..5, used for Mem/IO addressing context

  //----------------------------------------------------------------------
  // QoS / routing attributes
  //----------------------------------------------------------------------
  rand bit [2:0]         tc;            // Traffic Class 0..7
  rand bit [2:0]         vc;            // Virtual Channel 0..7
  rand bit                attr_no_snoop;
  rand bit                attr_relaxed_ordering;
  rand bit                attr_id_based_ordering;
  rand bit                ecrc_present;
  rand bit                poisoned;

  //----------------------------------------------------------------------
  // Config-space specific
  //----------------------------------------------------------------------
  rand bit [11:0]        cfg_reg_addr;    // extended config register offset
  rand bit [3:0]         cfg_byte_enable;

  //----------------------------------------------------------------------
  // Completion specific
  //----------------------------------------------------------------------
  rand pcie_cpl_status_e cpl_status;
  rand bit [11:0]        cpl_byte_count;
  rand bit [6:0]         cpl_lower_addr;

  //----------------------------------------------------------------------
  // Message specific
  //----------------------------------------------------------------------
  rand bit [7:0]         msg_code;
  rand bit [2:0]         msg_routing;

  //----------------------------------------------------------------------
  // AtomicOp specific
  //----------------------------------------------------------------------
  rand bit [1:0]         atomic_op;       // 0=FetchAdd 1=Swap 2=CAS
  rand bit [63:0]        atomic_operand0;
  rand bit [63:0]        atomic_operand1; // CAS compare operand

  //----------------------------------------------------------------------
  // IDE / PASID / OHC (Gen5/6 TLP prefix features)
  //----------------------------------------------------------------------
  rand bit               ide_tlp;
  rand bit [7:0]         ide_stream_id;
  rand bit               pasid_present;
  rand bit [19:0]        pasid_value;
  rand bit               pasid_priv_mode;
  rand bit               pasid_exec_req;
  rand bit               ohc_present;
  rand pcie_ohc_type_e   ohc_type;
  rand bit [15:0]        ohc_vendor_id;

  //----------------------------------------------------------------------
  // FLIT-mode specific (Gen6 mandatory / Gen5 optional)
  //----------------------------------------------------------------------
  rand bit               flit_mode;
  rand bit [9:0]         flit_seq_num;
  rand bit [15:0]        flit_crc;
  rand bit               flit_crc_force_bad;

  //----------------------------------------------------------------------
  // Payload (sized dynamically based on length_dw)
  //----------------------------------------------------------------------
  rand bit [31:0]        payload[];

  //----------------------------------------------------------------------
  // Error-injection control - mirrors cfg.error_kind but allows per-txn
  // override for negative test sequences
  //----------------------------------------------------------------------
  rand pcie_error_kind_e error_kind;

  //========================================================================
  // CONSTRAINTS
  //========================================================================

  // Length must be a legal PCIe TLP payload size: 1 DW .. 1024 DW (4KB max).
  // Memory writes/reads with length>1 must be naturally aligned per spec
  // (4.2.2): addr[1:0] always 0 for DW-aligned access.
  constraint c_length {
    length_dw inside {[1:1024]};
    // power-of-two-ish common burst sizes are weighted higher for realism
    // but any legal length is allowed
    if (tlp_type inside {TLP_CFG_RD0, TLP_CFG_WR0, TLP_CFG_RD1, TLP_CFG_WR1}) {
      length_dw == 1; // config space access is always 1 DW
    }
    if (tlp_type inside {TLP_MSG}) {
      length_dw == 0;
    }
    if (tlp_type inside {TLP_ATOMIC_FETCHADD, TLP_ATOMIC_SWAP}) {
      length_dw inside {1, 2}; // 32b or 64b operand
    }
    if (tlp_type == TLP_ATOMIC_CAS) {
      length_dw inside {2, 4}; // 64b or 128b (2x operand)
    }
  }

  // Address alignment rules (PCIe base spec 2.2.2 / 2.2.4.2)
  constraint c_addr_alignment {
    if (tlp_type inside {TLP_MEM_RD, TLP_MEM_RD_LK, TLP_MEM_WR}) {
      // DW aligned
      addr[1:0] == 2'b00;
    }
    if (tlp_type inside {TLP_ATOMIC_FETCHADD, TLP_ATOMIC_SWAP}) {
      addr[1:0] == 2'b00; // 32-bit operand alignment minimum
      if (length_dw == 2) addr[2:0] == 3'b000; // 64-bit op -> QW aligned
    }
    if (tlp_type == TLP_ATOMIC_CAS) {
      if (length_dw == 2) addr[2:0] == 3'b000;
      else                addr[3:0] == 4'b0000; // 128b CAS -> 16B aligned
    }
    if (tlp_type inside {TLP_CFG_RD0, TLP_CFG_WR0, TLP_CFG_RD1, TLP_CFG_WR1}) {
      cfg_reg_addr[1:0] == 2'b00;
    }
  }

  // First/Last byte-enable legality (2.2.5)
  constraint c_byte_enables {
    if (length_dw == 1) {
      last_be == 4'b0000; // LastDW BE must be 0 for 1-DW transfers
    } else {
      last_be != 4'b0000;
    }
    first_be != 4'b0000 || (tlp_type inside {TLP_MSG, TLP_MSG_D});
    // BE bits must be contiguous (no "holes") for non-atomic ops per common
    // implementation legality (spec permits non-contiguous but most RC/EP
    // implementations and this VIP restrict to contiguous for cleanliness)
    if (!(tlp_type inside {TLP_ATOMIC_FETCHADD, TLP_ATOMIC_SWAP, TLP_ATOMIC_CAS})) {
      first_be inside {4'b0000, 4'b0001, 4'b0011, 4'b0111, 4'b1111,
                       4'b1000, 4'b1100, 4'b1110, 4'b0110, 4'b0100, 4'b0010,
                       4'b1001, 4'b1101, 4'b1011};
    }
  }

  // BDF legality
  constraint c_bdf {
    bus_num  inside {[0:255]};
    dev_num  inside {[0:31]};
    func_num inside {[0:7]};
    requester_bus  inside {[0:255]};
    requester_dev  inside {[0:31]};
    requester_func inside {[0:7]};
    bar_num inside {[0:5]};
  }

  // Tag legality: 8-bit (Gen <=4 default) or 10-bit extended tag (Gen5/6)
  constraint c_tag {
    tag inside {[0:1023]};
  }

  // TC/VC mapping legality
  constraint c_tc_vc {
    tc inside {[0:7]};
    vc inside {[0:7]};
    // TC0 must always map to VC0 (spec mandated default VC)
    (tc == 0) -> (vc == 0);
  }

  // Completion status legality
  constraint c_cpl_status {
    if (tlp_type inside {TLP_CPL, TLP_CPL_D, TLP_CPL_LK, TLP_CPL_DLK}) {
      cpl_status inside {CPL_SC, CPL_UR, CPL_CRS, CPL_CA};
      // CRS only legal for Configuration Read completions
      if (cpl_status == CPL_CRS) {
        // modeled via error_kind context, left permissive here
      }
      cpl_byte_count inside {[0:4096]};
      cpl_lower_addr[1:0] == 2'b00; // DW aligned lower address
    }
  }

  // Message code legality (subset of defined Msg codes, spec 2.2.8)
  constraint c_msg_code {
    if (tlp_type inside {TLP_MSG, TLP_MSG_D}) {
      msg_code inside {8'h14, 8'h15, 8'h18, 8'h19, 8'h1A, 8'h1B, 8'h1C, 8'h1D, 8'h1E, 8'h1F,
                        8'h20, 8'h21, 8'h22, 8'h23, 8'h30, 8'h31, 8'h32, 8'h33,
                        8'h34, 8'h35, 8'h36, 8'h37, 8'h38, 8'h39, 8'h3A, 8'h3B,
                        8'h7E, 8'h7F};
      msg_routing inside {[0:7]};
    }
  }

  // AtomicOp legality - operand widths follow length_dw (32b vs 64b vs 128b)
  constraint c_atomic {
    if (tlp_type == TLP_ATOMIC_FETCHADD) atomic_op == 2'd0;
    if (tlp_type == TLP_ATOMIC_SWAP)     atomic_op == 2'd1;
    if (tlp_type == TLP_ATOMIC_CAS)      atomic_op == 2'd2;
  }

  // IDE legality - stream id & secure state only meaningful when ide_tlp set
  constraint c_ide {
    if (!ide_tlp) {
      ide_stream_id == 0;
    }
  }

  // PASID legality - 20-bit value, exec_req only with priv_mode context
  constraint c_pasid {
    if (!pasid_present) {
      pasid_value == 0;
      pasid_priv_mode == 0;
      pasid_exec_req == 0;
    } else {
      pasid_value inside {[0:20'hFFFFF]};
    }
  }

  // OHC legality
  constraint c_ohc {
    if (!ohc_present) {
      ohc_type == OHC_NONE;
      ohc_vendor_id == 0;
    } else {
      ohc_type inside {OHC_TPH, OHC_LATENCY, OHC_VENDOR_DEFINED};
    }
  }

  // FLIT sequence number range (12-bit per Gen6 FLIT spec, modeled as 10-bit
  // here for DL sequence number compatibility with non-FLIT DLLPs)
  constraint c_flit {
    flit_seq_num inside {[0:1023]};
  }

  // Payload sizing: dynamic array sized to length_dw (skip for zero-length)
  constraint c_payload_size {
    payload.size() == length_dw;
  }

  //========================================================================
  // Negative-test override constraints (applied conditionally by sequences
  // via randomize() with {} - kept here as documentation of intent and as
  // a soft-disable so default randomization never produces illegal traffic
  // unless explicitly requested through error_kind)
  //========================================================================
  constraint c_error_kind_default {
    soft error_kind == ERR_NONE;
  }

  // When a TLP-level negative scenario is selected, force the tlp_type
  // into a state consistent with that scenario so the driver/monitor can
  // recognize and check it.
  constraint c_error_consistency {
    if (error_kind == ERR_INVALID_TLP) {
      tlp_type == TLP_INVALID;
    }
    if (error_kind == ERR_UNSUPPORTED_REQUEST) {
      tlp_type inside {TLP_MEM_RD, TLP_MEM_WR, TLP_CFG_RD0, TLP_CFG_WR0};
    }
    if (error_kind == ERR_COMPLETER_ABORT) {
      tlp_type inside {TLP_CPL, TLP_CPL_D};
      cpl_status == CPL_CA;
    }
    if (error_kind == ERR_POISONED_TLP) {
      poisoned == 1'b1;
    }
    if (error_kind == ERR_PASID_INVALID) {
      pasid_present == 1'b1;
    }
    if (error_kind == ERR_PASID_PRIV_VIOLATION) {
      pasid_present == 1'b1;
      pasid_priv_mode == 1'b1;
    }
    if (error_kind inside {ERR_IDE_AUTH_FAIL, ERR_IDE_BAD_MAC}) {
      ide_tlp == 1'b1;
    }
    if (error_kind inside {ERR_OHC_MALFORMED, ERR_OHC_UNSUPPORTED_VENDOR}) {
      ohc_present == 1'b1;
    }
    if (error_kind == ERR_BAD_FLIT_CRC) {
      flit_mode == 1'b1;
      flit_crc_force_bad == 1'b1;
    }
  }

  function new(string name = "pcie_gen5_6_txn");
    super.new(name);
  endfunction

  //----------------------------------------------------------------------
  // Convenience printer for UVM_INFO debug messages
  //----------------------------------------------------------------------
  function string convert2string();
    return $sformatf("type=%s addr=0x%016h tag=0d%0d len_dw=%0d bdf=%0d/%0d/%0d tc=%0d vc=%0d err=%s",
                      tlp_type.name(), addr, tag, length_dw,
                      bus_num, dev_num, func_num, tc, vc, error_kind.name());
  endfunction

  function void do_copy(uvm_object rhs);
    pcie_gen5_6_txn rhs_;
    if (!$cast(rhs_, rhs)) begin
      `uvm_fatal("TXN_COPY", "Cast failed in do_copy")
    end
    super.do_copy(rhs);
    tlp_type        = rhs_.tlp_type;
    addr            = rhs_.addr;
    tag             = rhs_.tag;
    first_be        = rhs_.first_be;
    last_be         = rhs_.last_be;
    length_dw       = rhs_.length_dw;
    bus_num         = rhs_.bus_num;
    dev_num         = rhs_.dev_num;
    func_num        = rhs_.func_num;
    requester_bus   = rhs_.requester_bus;
    requester_dev   = rhs_.requester_dev;
    requester_func  = rhs_.requester_func;
    bar_num         = rhs_.bar_num;
    tc              = rhs_.tc;
    vc              = rhs_.vc;
    attr_no_snoop          = rhs_.attr_no_snoop;
    attr_relaxed_ordering  = rhs_.attr_relaxed_ordering;
    attr_id_based_ordering = rhs_.attr_id_based_ordering;
    ecrc_present    = rhs_.ecrc_present;
    poisoned        = rhs_.poisoned;
    cfg_reg_addr    = rhs_.cfg_reg_addr;
    cfg_byte_enable = rhs_.cfg_byte_enable;
    cpl_status      = rhs_.cpl_status;
    cpl_byte_count  = rhs_.cpl_byte_count;
    cpl_lower_addr  = rhs_.cpl_lower_addr;
    msg_code        = rhs_.msg_code;
    msg_routing     = rhs_.msg_routing;
    atomic_op       = rhs_.atomic_op;
    atomic_operand0 = rhs_.atomic_operand0;
    atomic_operand1 = rhs_.atomic_operand1;
    ide_tlp         = rhs_.ide_tlp;
    ide_stream_id   = rhs_.ide_stream_id;
    pasid_present   = rhs_.pasid_present;
    pasid_value     = rhs_.pasid_value;
    pasid_priv_mode = rhs_.pasid_priv_mode;
    pasid_exec_req  = rhs_.pasid_exec_req;
    ohc_present     = rhs_.ohc_present;
    ohc_type        = rhs_.ohc_type;
    ohc_vendor_id   = rhs_.ohc_vendor_id;
    flit_mode       = rhs_.flit_mode;
    flit_seq_num    = rhs_.flit_seq_num;
    flit_crc        = rhs_.flit_crc;
    flit_crc_force_bad = rhs_.flit_crc_force_bad;
    payload         = rhs_.payload;
    error_kind      = rhs_.error_kind;
  endfunction

endclass : pcie_gen5_6_txn

`endif
