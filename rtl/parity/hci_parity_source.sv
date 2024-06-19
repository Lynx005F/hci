/*
 * hci_core_assign.sv
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
 * The **hci_parity_source** module is used to monitor an input hci interface
 * stream `tcdm_main` and copy it to an output hci interface `tcdm_parity` which
 * only holds the handshake and control onfo, as well as one parity bit per data
 * element. Together with hci_parity_sink this allows for low area fault detection
 * on HCIby building a parity network that matches the original network.
 */


`include "hci_helpers.svh"

module hci_parity_source
  import hci_package::*;
# (
  parameter hci_size_parameter_t `HCI_SIZE_PARAM(tcdm_main) = '0
) (
  hci_core_intf.monitor    tcdm_main,
  hci_core_intf.initiator  tcdm_parity,
  output logic fault_detected_o
);

  localparam DW = `HCI_SIZE_GET_DW(tcdm_main);
  localparam BW = `HCI_SIZE_GET_BW(tcdm_main);

  // Directly assign single bit signals or signals that are control relevant
  assign tcdm_parity.req     = tcdm_main.req;
  assign tcdm_parity.wen     = tcdm_main.wen;
  assign tcdm_parity.be      = tcdm_main.be;
  assign tcdm_parity.r_ready = tcdm_main.r_ready;
  assign tcdm_parity.user    = tcdm_main.user;
  assign tcdm_parity.id      = tcdm_main.id;

  // Compress other signals
  assign tcdm_parity.add     = ^tcdm_main.add;
  for (genvar i = 0; i < DW/BW; i++) begin
    assign tcdm_parity.data [i]  = ^tcdm_main.data[i * BW +: BW];
  end
  assign tcdm_parity.ereq     = ^tcdm_main.ereq;
  assign tcdm_parity.ecc      = ^tcdm_main.ecc;

  // Calculate local signals for comparison
  logic local_main_egnt;
  logic local_main_r_evalid;
  logic local_main_r_ecc;

  assign local_main_egnt = ^tcdm_main.egnt;
  assign local_main_r_evalid = ^tcdm_main.r_evalid;
  assign local_main_r_ecc = ^tcdm_main.r_ecc;

  // Compare Signals
  assign fault_detected_o =
      ( tcdm_main.gnt       != tcdm_parity.gnt      ) |
      ( tcdm_main.r_data    != tcdm_parity.r_data   ) |
      ( tcdm_main.r_valid   != tcdm_parity.r_valid  ) |
      ( tcdm_main.r_user    != tcdm_parity.r_user   ) |
      ( tcdm_main.r_id      != tcdm_parity.r_id     ) |
      ( tcdm_main.r_opc     != tcdm_parity.r_opc    ) |
      ( local_main_egnt     != tcdm_parity.egnt     ) |
      ( local_main_r_evalid != tcdm_parity.r_evalid ) |
      ( tcdm_main.r_eready  != tcdm_parity.r_eready ) |
      ( local_main_r_ecc    != tcdm_parity.r_ecc    );

endmodule // hci_parity_source
