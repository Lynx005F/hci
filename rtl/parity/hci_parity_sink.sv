/*
 * hci_parity_sink.sv
 * Maurus Item <itemm@student.ethz.ch>
 *
 * Copyright (C) 2024 ETH Zurich, University of Bologna
 * Copyright and related rights are licensed under the Solderpad Hardware
 * License, Version 0.51 (the "License"); you may not use this file except in
 * compliance with the License.  You may obtain a copy of the License at
 * http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
 * or agreed to in writing, software, hardware and materials distributed under
 * this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
 * CONDITIONS OF ANY KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations under the License.
 */

/**
 * The **hci_parity_sink** module is used to monitor an input normal hci interface 
 * stream `tcdm_main` and compare it with a parity stream `tcdm_parity` which 
 * holds only the handshake and control info, as well as one parity bit per data 
 * element. Together with hci_parity_source this allows for low area fault 
 * detection on HCI by building a parity network that matches the 
 * original network.
 */

`include "hci_helpers.svh"

module hci_parity_sink 
  import hci_package::*;
#(
  parameter hci_size_parameter_t `HCI_SIZE_PARAM(tcdm_main) = '0
) (
  hci_core_intf.monitor   tcdm_main,
  hci_core_intf.target    tcdm_parity,
  output logic fault_detected_o
);
  
  localparam DW = `HCI_SIZE_GET_DW(tcdm_main);
  localparam BW = `HCI_SIZE_GET_BW(tcdm_main);

  // Directly assign single bit signals or signals that are control relevant
  assign tcdm_parity.gnt      = tcdm_main.gnt;
  assign tcdm_parity.r_data   = tcdm_main.r_data;
  assign tcdm_parity.r_valid  = tcdm_main.r_valid;
  assign tcdm_parity.r_user   = tcdm_main.r_user;
  assign tcdm_parity.r_id     = tcdm_main.r_id;
  assign tcdm_parity.r_opc    = tcdm_main.r_opc;
  assign tcdm_parity.r_eready = tcdm_main.r_eready;

  // Compress other signals
  assign tcdm_parity.egnt     = ^tcdm_main.egnt;
  assign tcdm_parity.r_evalid = ^tcdm_main.r_evalid;
  assign tcdm_parity.r_ecc    = ^tcdm_main.r_ecc;

  // Calculate local signals for comparison
  logic local_main_add;
  logic [DW/BW-1:0] local_main_data;
  logic local_main_ereq;
  logic local_main_ecc;

  // Calculate parity bits for non-control signals
  assign local_main_add = ^tcdm_main.add;
  for (genvar i = 0; i < DW/BW; i++) begin
    assign local_main_data[i] = ^tcdm_main.data[i * BW +: BW];
  end
  assign local_main_ereq = ^tcdm_main.ereq;
  assign local_main_ecc = ^tcdm_main.ecc;

  // Compare Signals
  assign fault_detected_o = 
      ( tcdm_parity.req      != tcdm_main.req      ) |
      ( tcdm_parity.wen      != tcdm_main.wen      ) |
      ( tcdm_parity.be       != tcdm_main.be       ) |
      ( tcdm_parity.r_ready  != tcdm_main.r_ready  ) |
      ( tcdm_parity.user     != tcdm_main.user     ) |
      ( tcdm_parity.id       != tcdm_main.id       ) |
      ( tcdm_parity.add      != local_main_add     ) |
      ( tcdm_parity.data     != local_main_data    ) |
      ( tcdm_parity.ereq     != local_main_ereq    ) |
      ( tcdm_parity.ecc      != local_main_ecc     );

endmodule // hci_parity_sink
