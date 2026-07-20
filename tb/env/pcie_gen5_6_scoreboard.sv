`ifndef PCIE_GEN5_6_SCOREBOARD_SV
`define PCIE_GEN5_6_SCOREBOARD_SV

`uvm_analysis_imp_decl(_tl)
`uvm_analysis_imp_decl(_dl)
`uvm_analysis_imp_decl(_pipe)

class pcie_gen5_6_scoreboard extends uvm_component;
  `uvm_component_utils(pcie_gen5_6_scoreboard)

  uvm_analysis_imp_tl   #(pcie_tlp_item,         pcie_gen5_6_scoreboard) tl_imp;
  uvm_analysis_imp_dl   #(pcie_dlp_item,         pcie_gen5_6_scoreboard) dl_imp;
  uvm_analysis_imp_pipe #(pcie_pipe_symbol_item, pcie_gen5_6_scoreboard) pipe_imp;

  pcie_gen5_6_cfg cfg;
  pcie_tlp_item outstanding_by_tag[int unsigned];
  pcie_flit_item replay_buffer[int unsigned];
  int unsigned expected_flit_seq;
  int unsigned acked_flit_seq;
  int unsigned posted_cnt;
  int unsigned nonposted_cnt;
  int unsigned completion_cnt;
  int unsigned error_cnt[pcie_error_kind_e];
  int signed   ph_credit;
  int signed   pd_credit;
  int signed   nph_credit;
  int signed   npd_credit;
  int signed   cplh_credit;
  int signed   cpld_credit;

  function new(string name = "pcie_gen5_6_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    tl_imp   = new("tl_imp", this);
    dl_imp   = new("dl_imp", this);
    pipe_imp = new("pipe_imp", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(pcie_gen5_6_cfg)::get(this, "", "cfg", cfg)) begin
      cfg = pcie_gen5_6_cfg::type_id::create("cfg");
    end
    expected_flit_seq = 1;
    acked_flit_seq    = 0;
    ph_credit         = 64;
    pd_credit         = 256;
    nph_credit        = 64;
    npd_credit        = 256;
    cplh_credit       = 64;
    cpld_credit       = 256;
  endfunction

  function void write_tl(pcie_tlp_item tr);
`uvm_info("SB",
          $sformatf("TL received type=%s tag=%0d",
                    tr.tlp_type.name(),
                    tr.tag),
          UVM_LOW)



  if (tr.is_posted()) begin
      posted_cnt++;
      ph_credit--;
    end else if (tr.needs_completion()) begin
      nonposted_cnt++;
      nph_credit--;
      outstanding_by_tag[tr.tag] = tr;
    end else if (tr.tlp_type inside {TLP_CPL, TLP_CPLD}) begin
      completion_cnt++;
      if (!outstanding_by_tag.exists(tr.tag)) begin
        `uvm_error(get_type_name(), $sformatf("Unexpected completion tag=%0d", tr.tag))
      end else begin
        outstanding_by_tag.delete(tr.tag);
      end
    end

    if (tr.error_kind != ERR_NONE) begin
      error_cnt[tr.error_kind]++;
    end
    if ((ph_credit < 0) || (nph_credit < 0)) begin
      `uvm_error(get_type_name(), "Flow-control credit underflow detected by scoreboard")
    end
  endfunction

  function void write_dl(pcie_dlp_item tr);
    if (tr.dlp_type == DLP_ACK) begin
      acked_flit_seq = tr.ack_nak_seq_num;
      foreach (replay_buffer[idx]) begin
        if (idx <= acked_flit_seq) begin
          replay_buffer.delete(idx);
        end
      end
    end else if (tr.dlp_type == DLP_NAK) begin
      if (!replay_buffer.exists(tr.ack_nak_seq_num + 1)) begin
        `uvm_warning(get_type_name(), $sformatf("NAK requested seq %0d but replay buffer lacks entry", tr.ack_nak_seq_num + 1))
      end
    end

    ph_credit   = tr.ph_credit;
    pd_credit   = tr.pd_credit;
    nph_credit  = tr.nph_credit;
    npd_credit  = tr.npd_credit;
    cplh_credit = tr.cplh_credit;
    cpld_credit = tr.cpld_credit;
  endfunction

function void write_pipe(pcie_pipe_symbol_item tr);

  `uvm_info("SB_PIPE",
            $sformatf("sym=%s err=%s",
                      tr.symbol_type.name(),
                      tr.error_kind.name()),
            UVM_LOW)

  
endfunction


 /* function void write_pipe(pcie_pipe_symbol_item tr);
    if ((tr.symbol_type == PIPE_SYM_FLIT) && (cfg.enable_flit_mode)) begin
      if (tr.error_kind == ERR_BAD_FLIT_SEQ) begin
        error_cnt[ERR_BAD_FLIT_SEQ]++;
      end
      if (tr.error_kind inside {ERR_BAD_CRC, ERR_BAD_ECC, ERR_DROP_FLIT, ERR_DUP_FLIT}) begin
        error_cnt[tr.error_kind]++;
      end
      expected_flit_seq++;
    end
  endfunction
*/
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    if (outstanding_by_tag.num() != 0) begin
      `uvm_warning(get_type_name(), $sformatf("Outstanding tags remaining: %0d", outstanding_by_tag.num()))
    end
    `uvm_info(get_type_name(), $sformatf("posted=%0d nonposted=%0d completions=%0d", posted_cnt, nonposted_cnt, completion_cnt), UVM_LOW)
  endfunction
endclass : pcie_gen5_6_scoreboard

`endif

























































































































