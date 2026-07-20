
`ifndef PCIE_TLP_ITEM_SV
`define PCIE_TLP_ITEM_SV

class pcie_tlp_item extends uvm_sequence_item;
//  `uvm_object_utils(pcie_tlp_item)

  //--------------------------------------------------------------------------
  // Core TLP identity
  //--------------------------------------------------------------------------
  rand pcie_tlp_type_e   tlp_type;
  rand bit [15:0]        requester_id;
  rand bit [15:0]        completer_id;
  rand bit [9:0]         tag;
  rand bit [63:0]        addr;
  rand bit [9:0]         length_dw;
  rand bit [3:0]         first_be;
  rand bit [3:0]         last_be;
  rand bit [2:0]         traffic_class;
  rand bit [2:0]         attr;
  rand bit               poisoned;
  rand bit               ecrc_present;
  rand bit               ide_present;
  rand bit [19:0]        pasid;
  rand bit [7:0]         ohc_vector;
  rand bit [31:0]        payload_dw[];

  //--------------------------------------------------------------------------
  // Fields mirrored from pcie_gen5_6_txn (Step 2 additions)
  // Required by send_tlp() randomize() with {} block in pcie_gen5_6_base_seq
  //--------------------------------------------------------------------------
  rand bit [7:0]         bus_num;
  rand bit [4:0]         dev_num;
  rand bit [2:0]         func_num;
  rand bit [7:0]         requester_bus;
  rand bit [4:0]         requester_dev;
  rand bit [2:0]         requester_func;
  rand bit [5:0]         bar_num;
  rand bit [2:0]         tc;
  rand bit [2:0]         vc;
  rand bit               attr_no_snoop;
  rand bit               attr_relaxed_ordering;
  rand bit               attr_id_based_ordering;
  rand bit [11:0]        cfg_reg_addr;
  rand bit [3:0]         cfg_byte_enable;
  rand pcie_cpl_status_e cpl_status;
  rand bit [11:0]        cpl_byte_count;
  rand bit [6:0]         cpl_lower_addr;
  rand bit [7:0]         msg_code;
  rand bit [2:0]         msg_routing;
  rand bit [1:0]         atomic_op;
  rand bit [63:0]        atomic_operand0;
  rand bit [63:0]        atomic_operand1;
  rand bit               ide_tlp;
  rand bit [7:0]         ide_stream_id;
  rand bit               pasid_present;
  rand bit [19:0]        pasid_value;
  rand bit               pasid_priv_mode;
  rand bit               pasid_exec_req;
  rand bit               ohc_present;
  rand pcie_ohc_type_e   ohc_type;
  rand bit [15:0]        ohc_vendor_id;
  rand bit               flit_mode;
  rand bit [9:0]         flit_seq_num;
  rand bit [31:0]        payload[];

  //--------------------------------------------------------------------------
  // Error kind (renamed from pcie_error_inject_e)
  //--------------------------------------------------------------------------
  rand pcie_error_kind_e error_kind;

  //--------------------------------------------------------------------------
  // Error injection force bits (Step 2 additions)
  // Set by apply_error_injection() in pcie_gen5_6_base_seq; consumed by driver
  //--------------------------------------------------------------------------
  bit force_invalid_type;
  bit force_bad_lcrc;
  bit force_bad_ecrc;
  bit force_replay_timeout;
  bit force_credit_exhaust;
  bit force_unsupported_req;
  bit force_completer_abort;
  bit force_ide_auth_fail;
  bit force_ide_bad_mac;
  bit force_pasid_invalid;
  bit force_pasid_priv_viol;
  bit force_ohc_malformed;
  bit force_ohc_bad_vendor;
  bit force_bad_flit_crc;

  //--------------------------------------------------------------------------
  // Constraints
  //--------------------------------------------------------------------------
  constraint c_len     { length_dw inside {[1:256]}; payload_dw.size() == length_dw; }
  constraint c_be      { first_be != 4'h0; if (length_dw == 1) last_be == 4'h0; }
  constraint c_align   { addr[1:0] == 2'b00; }
  constraint c_cfg_len { if (tlp_type inside {TLP_CFG_RD0, TLP_CFG_WR0,
                                               TLP_CFG_RD1, TLP_CFG_WR1})
                           length_dw == 1; }
  constraint c_flit_ohc { if (ohc_vector != 0)
                            tlp_type inside {TLP_MEM_RD, TLP_MEM_WR,
                                             TLP_MSG, TLP_MSG_D}; }
  constraint c_error_default { soft error_kind == ERR_NONE; }

  `uvm_object_utils_begin(pcie_tlp_item)
    `uvm_field_enum(pcie_tlp_type_e,    tlp_type,              UVM_ALL_ON)
    `uvm_field_int(requester_id,                               UVM_ALL_ON)
    `uvm_field_int(completer_id,                               UVM_ALL_ON)
    `uvm_field_int(tag,                                        UVM_ALL_ON)
    `uvm_field_int(addr,                                       UVM_ALL_ON)
    `uvm_field_int(length_dw,                                  UVM_ALL_ON)
    `uvm_field_int(first_be,                                   UVM_ALL_ON)
    `uvm_field_int(last_be,                                    UVM_ALL_ON)
    `uvm_field_int(traffic_class,                              UVM_ALL_ON)
    `uvm_field_int(attr,                                       UVM_ALL_ON)
    `uvm_field_int(poisoned,                                   UVM_ALL_ON)
    `uvm_field_int(ecrc_present,                               UVM_ALL_ON)
    `uvm_field_int(ide_present,                                UVM_ALL_ON)
    `uvm_field_int(pasid,                                      UVM_ALL_ON)
    `uvm_field_int(ohc_vector,                                 UVM_ALL_ON)
    `uvm_field_array_int(payload_dw,                           UVM_ALL_ON)
    `uvm_field_enum(pcie_error_kind_e,  error_kind,            UVM_ALL_ON)
    `uvm_field_int(bus_num,                                    UVM_ALL_ON)
    `uvm_field_int(dev_num,                                    UVM_ALL_ON)
    `uvm_field_int(func_num,                                   UVM_ALL_ON)
    `uvm_field_int(requester_bus,                              UVM_ALL_ON)
    `uvm_field_int(requester_dev,                              UVM_ALL_ON)
    `uvm_field_int(requester_func,                             UVM_ALL_ON)
    `uvm_field_int(bar_num,                                    UVM_ALL_ON)
    `uvm_field_int(tc,                                         UVM_ALL_ON)
    `uvm_field_int(vc,                                         UVM_ALL_ON)
    `uvm_field_int(attr_no_snoop,                              UVM_ALL_ON)
    `uvm_field_int(attr_relaxed_ordering,                      UVM_ALL_ON)
    `uvm_field_int(attr_id_based_ordering,                     UVM_ALL_ON)
    `uvm_field_int(cfg_reg_addr,                               UVM_ALL_ON)
    `uvm_field_int(cfg_byte_enable,                            UVM_ALL_ON)
    `uvm_field_enum(pcie_cpl_status_e,  cpl_status,            UVM_ALL_ON)
    `uvm_field_int(cpl_byte_count,                             UVM_ALL_ON)
    `uvm_field_int(cpl_lower_addr,                             UVM_ALL_ON)
    `uvm_field_int(msg_code,                                   UVM_ALL_ON)
    `uvm_field_int(msg_routing,                                UVM_ALL_ON)
    `uvm_field_int(atomic_op,                                  UVM_ALL_ON)
    `uvm_field_int(atomic_operand0,                            UVM_ALL_ON)
    `uvm_field_int(atomic_operand1,                            UVM_ALL_ON)
    `uvm_field_int(ide_tlp,                                    UVM_ALL_ON)
    `uvm_field_int(ide_stream_id,                              UVM_ALL_ON)
    `uvm_field_int(pasid_present,                              UVM_ALL_ON)
    `uvm_field_int(pasid_value,                                UVM_ALL_ON)
    `uvm_field_int(pasid_priv_mode,                            UVM_ALL_ON)
    `uvm_field_int(pasid_exec_req,                             UVM_ALL_ON)
    `uvm_field_int(ohc_present,                                UVM_ALL_ON)
    `uvm_field_enum(pcie_ohc_type_e,    ohc_type,              UVM_ALL_ON)
    `uvm_field_int(ohc_vendor_id,                              UVM_ALL_ON)
    `uvm_field_int(flit_mode,                                  UVM_ALL_ON)
    `uvm_field_int(flit_seq_num,                               UVM_ALL_ON)
    `uvm_field_array_int(payload,                              UVM_ALL_ON)
    `uvm_field_int(force_invalid_type,                         UVM_ALL_ON)
    `uvm_field_int(force_bad_lcrc,                             UVM_ALL_ON)
    `uvm_field_int(force_bad_ecrc,                             UVM_ALL_ON)
    `uvm_field_int(force_replay_timeout,                       UVM_ALL_ON)
    `uvm_field_int(force_credit_exhaust,                       UVM_ALL_ON)
    `uvm_field_int(force_unsupported_req,                      UVM_ALL_ON)
    `uvm_field_int(force_completer_abort,                      UVM_ALL_ON)
    `uvm_field_int(force_ide_auth_fail,                        UVM_ALL_ON)
    `uvm_field_int(force_ide_bad_mac,                          UVM_ALL_ON)
    `uvm_field_int(force_pasid_invalid,                        UVM_ALL_ON)
    `uvm_field_int(force_pasid_priv_viol,                      UVM_ALL_ON)
    `uvm_field_int(force_ohc_malformed,                        UVM_ALL_ON)
    `uvm_field_int(force_ohc_bad_vendor,                       UVM_ALL_ON)
    `uvm_field_int(force_bad_flit_crc,                         UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "pcie_tlp_item");
    super.new(name);
    error_kind = ERR_NONE;
  endfunction

  function bit is_posted();
    return (tlp_type inside {TLP_MEM_WR, TLP_MSG, TLP_MSG_D});
  endfunction

  function bit needs_completion();
    return (tlp_type inside {TLP_MEM_RD, TLP_CFG_RD0, TLP_CFG_WR0,
                              TLP_CFG_RD1, TLP_CFG_WR1,
                              TLP_ATOMIC_FETCHADD, TLP_ATOMIC_SWAP,
                              TLP_ATOMIC_CAS});
  endfunction
endclass : pcie_tlp_item

`endif



































