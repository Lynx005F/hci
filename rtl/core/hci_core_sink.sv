/*
 * hci_core_sink.sv
 * Francesco Conti <f.conti@unibo.it>
 *
 * Copyright (C) 2014-2020 ETH Zurich, University of Bologna
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
 * The **hwpe_stream_sink** module is the high-level sink streamer
 * performing a series of stores on a HWPE-Mem or HWPE-MemDecoupled interface
 * from an incoming HWPE-Stream data stream from a HWPE engine/datapath.
 * The sink streamer is a composite module that makes use of many other
 * fundamental IPs. Its architecture is shown in :numfig: `_hwpe_stream_sink_archi`.
 *
 * .. _hwpe_stream_sink_archi:
 * .. figure:: img/hwpe_stream_sink_archi.*
 *   :figwidth: 90%
 *   :width: 90%
 *   :align: center
 *
 *   Architecture of the source streamer.
 *
 * Fundamentally, a ink streamer acts as a specialized DMA engine acting
 * out a predefined pattern from an **hwpe_stream_addressgen** to perform
 * a burst of stores via a HWPE-Mem interface, consuming a HWPE-Stream data
 * stream into the HWPE-Mem `data` field.
 *
 * The sink streamer indifferently supports standard HWPE-Mem or delayed
 * HWPE-MemDecoupled accesses. This is due to the nature of store streams,
 * that are unidirectional (i.e. `addr` and `data` move in the same direction)
 * and hence insensitive to latency.
 *
 * .. tabularcolumns:: |l|l|J|
 * .. _hwpe_stream_sink_params:
 * .. table:: **hwpe_stream_sink** design-time parameters.
 *
 *   +-------------------+-------------+------------------------------------------------------------------------------------------------------------------------+
 *   | **Name**          | **Default** | **Description**                                                                                                        |
 *   +-------------------+-------------+------------------------------------------------------------------------------------------------------------------------+
 *   | *USE_TCDM_FIFOS*  | 0           | If 1, the module produces a HWPE-MemDecoupled interface and includes a TCDM FIFO directly inside.                      |
 *   +-------------------+-------------+------------------------------------------------------------------------------------------------------------------------+
 *   | *DATA_WIDTH*      | 32          | Width of input/output streams.                                                                                         |
 *   +-------------------+-------------+------------------------------------------------------------------------------------------------------------------------+
 *   | *LATCH_FIFO*      | 0           | If 1, use latches instead of flip-flops (requires special constraints in synthesis).                                   |
 *   +-------------------+-------------+------------------------------------------------------------------------------------------------------------------------+
 *   | *TRANS_CNT*       | 16          | Number of bits supported in the transaction counter of the address generator, which will overflow at 2^ `TRANS_CNT`.   |
 *   +-------------------+-------------+------------------------------------------------------------------------------------------------------------------------+
 *
 * .. tabularcolumns:: |l|l|J|
 * .. _hwpe_stream_sink_ctrl:
 * .. table:: **hwpe_stream_sink** input control signals.
 *
 *   +-------------------+---------------------+-------------------------------------------------------------------------+
 *   | **Name**          | **Type**            | **Description**                                                         |
 *   +-------------------+---------------------+-------------------------------------------------------------------------+
 *   | *req_start*       | `logic`             | When 1, the sink streamer operation is started if it is ready.          |
 *   +-------------------+---------------------+-------------------------------------------------------------------------+
 *   | *addressgen_ctrl* | `ctrl_addressgen_t` | Configuration of the address generator (see **hwpe_stream_addressgen**). |
 *   +-------------------+---------------------+-------------------------------------------------------------------------+
 *
 * .. tabularcolumns:: |l|l|J|
 * .. _hwpe_stream_sink_flags:
 * .. table:: **hwpe_stream_sink** output flags.
 *
 *   +--------------------+----------------------+----------------------------------------------------------+
 *   | **Name**           | **Type**             | **Description**                                          |
 *   +--------------------+----------------------+----------------------------------------------------------+
 *   | *ready_start*      | `logic`              | 1 when the sink streamer is ready to start operation.    |
 *   +--------------------+----------------------+----------------------------------------------------------+
 *   | *done*             | `logic`              | 1 for one cycle when the streamer ends operation.        |
 *   +--------------------+----------------------+----------------------------------------------------------+
 *   | *addressgen_flags* | `flags_addressgen_t` | Address generator flags (see **hwpe_stream_addressgen**). |
 *   +--------------------+----------------------+----------------------------------------------------------+
 *   | *ready_fifo*       | `logic`              | Unused.                                                  |
 *   +--------------------+----------------------+----------------------------------------------------------+
 *
 */

import hwpe_stream_package::*;

module hci_core_sink
#(
  // Stream interface params
  parameter int unsigned DATA_WIDTH     = 32,
  parameter int unsigned TCDM_FIFO_DEPTH = 0
)
(
  input logic clk_i,
  input logic rst_ni,
  input logic test_mode_i,
  input logic clear_i,

  // hwpe_stream_intf_tcdm.master tcdm [NB_TCDM_PORTS-1:0],
  hci_core_intf.master         tcdm,
  hwpe_stream_intf_stream.sink stream,

  // control plane
  input  ctrl_sourcesink_t    ctrl_i,
  output flags_sourcesink_t   flags_o
);

  state_sourcesink_t cs, ns;

  logic [31:0]             gen_addr;
  logic [DATA_WIDTH/8-1:0] gen_strb;

  logic address_gen_en;
  logic address_gen_clr;
  logic done;

  logic clk_realign_gated;
  logic clk_realign_en /* verilator clock_enable */;
  logic tcdm_inflight;

  hwpe_stream_intf_stream #(
    .DATA_WIDTH ( DATA_WIDTH )
  ) realigned_stream (
    .clk ( clk_realign_gated )
  );

  hci_core_intf #(
    .DW ( DATA_WIDTH )
  ) tcdm_prefifo (
    .clk ( clk_i )
  );

  hwpe_stream_addressgen #(
    .STEP         ( DATA_WIDTH/8             ),
    .REALIGN_TYPE ( HWPE_STREAM_REALIGN_SINK ),
    .DELAY_FLAGS  ( 1                        )
  ) i_addressgen (
    .clk_i          ( clk_i                    ),
    .rst_ni         ( rst_ni                   ),
    .test_mode_i    ( test_mode_i              ),
    .enable_i       ( address_gen_en           ),
    .clear_i        ( address_gen_clr          ),
    .gen_addr_o     ( gen_addr                 ),
    .gen_strb_o     ( gen_strb                 ),
    .ctrl_i         ( ctrl_i.addressgen_ctrl   ),
    .flags_o        ( flags_o.addressgen_flags )
  );

  /* clock gating */
  assign clk_realign_en = flags_o.addressgen_flags.realign_flags.enable;
  cluster_clock_gating i_realign_gating (
    .clk_i     ( clk_i             ),
    .test_en_i ( test_mode_i       ),
    .en_i      ( clk_realign_en    ),
    .clk_o     ( clk_realign_gated )
  );

  hwpe_stream_sink_realign #(
    .DATA_WIDTH ( DATA_WIDTH )
  ) i_realign (
    .clk_i       ( clk_realign_gated                      ),
    .rst_ni      ( rst_ni                                 ),
    .test_mode_i ( test_mode_i                            ),
    .clear_i     ( clear_i                                ),
    .ctrl_i      ( flags_o.addressgen_flags.realign_flags ),
    .strb_i      ( gen_strb                               ),
    .push_i      ( stream                                 ),
    .pop_o       ( realigned_stream                       )
  );

  // hci port binding
  assign tcdm_prefifo.req   = (cs == STREAM_WORKING) ? realigned_stream.valid : '0;
  assign tcdm_prefifo.add   = (cs == STREAM_WORKING) ? gen_addr               : '0;
  assign tcdm_prefifo.wen   = '0;
  assign tcdm_prefifo.be    = (cs == STREAM_WORKING) ? realigned_stream.strb  : '0;
  assign tcdm_prefifo.data  = (cs == STREAM_WORKING) ? realigned_stream.data  : '0;
  assign tcdm_prefifo.boffs = '0;
  assign tcdm_prefifo.lrdy  = '1;
  assign realigned_stream.ready = ~realigned_stream.valid | tcdm_prefifo.gnt;

  generate

    if(TCDM_FIFO_DEPTH != 0) begin: tcdm_fifos_gen

      hwpe_stream_tcdm_fifo_store #(
        .FIFO_DEPTH ( TCDM_FIFO_DEPTH )
      ) i_tcdm_fifo (
        .clk_i       ( clk_i        ),
        .rst_ni      ( rst_ni       ),
        .clear_i     ( clear_i      ),
        .tcdm_slave  ( tcdm_prefifo ),
        .tcdm_master ( tcdm         ),
        .flags_o     (              )
      );

    end
    else begin: no_tcdm_fifos_gen

      hci_core_assign i_tcdm_assign (
        .tcdm_slave  ( tcdm_prefifo ),
        .tcdm_master ( tcdm         )
      );

    end

  endgenerate

  assign tcdm_inflight = tcdm.req;

  always_ff @(posedge clk_i or negedge rst_ni)
  begin : done_sink_ff
    if(~rst_ni)
      flags_o.done <= 1'b0;
    else if(clear_i)
      flags_o.done <= 1'b0;
    else
      flags_o.done <= done;
  end

  always_ff @(posedge clk_i, negedge rst_ni)
  begin : fsm_seq
    if(rst_ni == 1'b0) begin
      cs <= STREAM_IDLE;
    end
    else if(clear_i == 1'b1) begin
      cs <= STREAM_IDLE;
    end
    else begin
      cs <= ns;
    end
  end

  always_comb
  begin : fsm_comb
    done      = 1'b0;
    flags_o.ready_start = 1'b0;
    address_gen_en     = 1'b0;
    address_gen_clr    = clear_i;
    case(cs)
      STREAM_IDLE : begin
        flags_o.ready_start = 1'b1;
        if(ctrl_i.req_start) begin
          ns = STREAM_WORKING;
          address_gen_en = stream.valid & stream.ready;
        end
        else begin
          ns = STREAM_IDLE;
          address_gen_en = 1'b0;
        end
      end
      STREAM_WORKING : begin
        if(stream.valid & stream.ready) begin
          ns = STREAM_WORKING;
          address_gen_en = 1'b1;
        end
        else if(flags_o.addressgen_flags.realign_flags.enable & flags_o.addressgen_flags.realign_flags.last) begin
          ns = STREAM_WORKING;
          address_gen_en = 1'b1;
        end
        else if(~flags_o.addressgen_flags.in_progress & tcdm_inflight) begin // if transactions in flight, let them end
          ns = STREAM_WORKING;
          address_gen_en  = 1'b0;
        end
        else if(~flags_o.addressgen_flags.in_progress) begin
          ns = STREAM_IDLE;
          done = 1'b1;
          address_gen_en  = 1'b0;
          address_gen_clr = 1'b1;
        end
        else begin
          ns = STREAM_WORKING;
          address_gen_en = 1'b0;
        end
      end
      default : begin
        ns = STREAM_IDLE;
        address_gen_en = 1'b0;
      end
    endcase
  end

endmodule // hci_core_sink
