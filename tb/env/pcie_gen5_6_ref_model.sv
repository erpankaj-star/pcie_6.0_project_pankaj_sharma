




`ifndef PCIE_GEN5_6_REF_MODEL_SV
`define PCIE_GEN5_6_REF_MODEL_SV

class pcie_gen5_6_ref_model extends uvm_component;
  `uvm_component_utils(pcie_gen5_6_ref_model)

  pcie_gen5_6_cfg cfg;

  function new(string name = "pcie_gen5_6_ref_model", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function pcie_flit_item tlp_to_flit(pcie_tlp_item tlp, int unsigned seq);
    pcie_flit_item flit = pcie_flit_item::type_id::create("flit");
    flit.flit_seq_num = seq[9:0];
    flit.pack_tlp(tlp);
    flit.crc_ok            = (tlp.error_kind != ERR_BAD_CRC);
    flit.ecc_uncorrectable = (tlp.error_kind == ERR_BAD_ECC);
    return flit;
  endfunction

  function bit legal_ltssm_transition(pcie_ltssm_state_e from_s, pcie_ltssm_state_e to_s);
    if (from_s == to_s) begin
      return 1'b1;
    end
    unique case (from_s)
      LTSSM_DETECT_QUIET:                   return (to_s == LTSSM_DETECT_ACTIVE);
      LTSSM_DETECT_ACTIVE:                  return (to_s inside {LTSSM_POLLING_ACTIVE, LTSSM_DETECT_QUIET});
      LTSSM_POLLING_ACTIVE:                 return (to_s inside {LTSSM_POLLING_CONFIGURATION, LTSSM_POLLING_COMPLIANCE});
      LTSSM_POLLING_CONFIGURATION:          return (to_s inside {LTSSM_CONFIGURATION_LINKWIDTH_START, LTSSM_POLLING_SPEED});
      LTSSM_CONFIGURATION_LINKWIDTH_START:  return (to_s == LTSSM_CONFIGURATION_LINKWIDTH_ACCEPT);
      LTSSM_CONFIGURATION_LINKWIDTH_ACCEPT: return (to_s == LTSSM_CONFIGURATION_LANENUM_ACCEPT);
      LTSSM_CONFIGURATION_LANENUM_ACCEPT:   return (to_s == LTSSM_CONFIGURATION_COMPLETE);
      LTSSM_CONFIGURATION_COMPLETE:         return (to_s == LTSSM_CONFIGURATION_IDLE);
      LTSSM_CONFIGURATION_IDLE:             return (to_s inside {LTSSM_L0, LTSSM_RECOVERY_EQUALIZATION});
      LTSSM_RECOVERY_EQUALIZATION:          return (to_s inside {LTSSM_RECOVERY_SPEED, LTSSM_RECOVERY_RCVRCFG});
      LTSSM_RECOVERY_SPEED:                 return (to_s == LTSSM_RECOVERY_RCVRCFG);
      LTSSM_RECOVERY_RCVRCFG:               return (to_s == LTSSM_RECOVERY_IDLE);
      LTSSM_RECOVERY_IDLE:                  return (to_s == LTSSM_L0);
      LTSSM_L0:                             return (to_s inside {LTSSM_L0S, LTSSM_L0P, LTSSM_L1, LTSSM_L2,
                                                                  LTSSM_RECOVERY_RCVRLOCK, LTSSM_DISABLED,
                                                                  LTSSM_HOT_RESET});
      default:                              return 1'b1;
    endcase
  endfunction
endclass : pcie_gen5_6_ref_model

`endif









































