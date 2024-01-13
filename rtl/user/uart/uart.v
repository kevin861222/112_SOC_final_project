module uart #(
  parameter BAUD_RATE = 9600 
)(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif
  // Wishbone Slave ports (WB MI A)
  input wire    wb_clk_i,
  input wire    wb_rst_i,
  input wire    wbs_stb_i,
  input wire    wbs_cyc_i,
  input wire    wbs_we_i,
  input wire    [3:0] wbs_sel_i,
  input wire    [31:0] wbs_dat_i,
  input wire    [31:0] wbs_adr_i,
  output wire   wbs_ack_o,
  output wire   [31:0] wbs_dat_o,

  // IO ports
  input  [`MPRJ_IO_PADS-1:0] io_in, // The io_in[..] signals are from the pad to the user project and are always
									// active unless the pad has been configured with the "input disable" bit set.
  output [`MPRJ_IO_PADS-1:0] io_out,// The io_out[..] signals are from the user project to the pad.
  output [`MPRJ_IO_PADS-1:0] io_oeb,// The io_oeb[..] signals are from the user project to the pad cell.  This
									// controls the direction of the pad when in bidirectional mode.  When set to
									// value zero, the pad direction is output and the value of io_out[..] appears
									// on the pad.  When set to value one, the pad direction is input and the pad
									// output buffer is disabled.

  // irq
  output user_irq
);

  localparam rx_IDLE = 2'd0,
             rx_START = 2'd1,
             rx_IRQ = 2'd2,
             rx_WAIT_READ = 2'd3;

  localparam tx_IDLE = 2'd0,
             tx_FCLEAR = 2'd1,
             tx_START = 2'd2,
             tx_CLEAR = 2'd3;

  // UART 
  wire  tx;
  wire  rx;

  assign io_oeb[6] = 1'b0; // Set mprj_io_31 to output
  assign io_oeb[5] = 1'b1; // Set mprj_io_30 to input
  assign io_out[6] = tx;	// Connect mprj_io_6 to tx
  assign rx = io_in[5];	// Connect mprj_io_5 to rx
  // CSR
  wire [7:0] rx_data; 
  wire irq_en;
  wire rx_finish;
  wire rx_busy;
  wire [7:0] tx_data;
  wire tx_start_clear;
  wire tx_start;
  wire tx_busy;
  wire wb_valid;
  wire frame_err;
  // irq
  wire irq;
  reg irq_fifo;
  reg  user_irq_q, user_irq_d;

  reg [3:0] irq_count_q, irq_count_d;
  reg [3:0] rx_irq_count_d, rx_irq_count_q;
  wire [7:0] rx_data_fifo, tx_data_fifo;
  reg rx_finish_fifo_d, rx_finish_fifo_q;
  reg [1:0] rx_state_cs, rx_state_ns; 
  wire rx_full, rx_empty;

  reg [3:0] tx_start_count_q, tx_start_count_d;
  reg tx_start_fifo, rx_fifo_ren;
  reg [1:0] tx_state_cs, tx_state_ns; 
  wire tx_full, tx_empty;
  reg tx_start_wen, tx_clear_ren, tx_clear_fifo;
  reg rx_rstfifo, tx_rstfifo;

  assign user_irq = user_irq_q;	// Use USER_IRQ_0
  always @(*) begin
      user_irq_d = 0;
      irq_count_d = irq_count_q;

      if (irq) begin
          irq_count_d = irq_count_q + 1;
      end
      if (irq_count_q == 8) begin
          irq_count_d = irq;
          user_irq_d = 1;
      end
  end

// rx fifo
  always @(*) begin
    if(irq) 
      rx_irq_count_d = rx_irq_count_q + 1'd1;
    else if(rx_finish)
      rx_irq_count_d = rx_irq_count_q - 1'd1;
    else  
      rx_irq_count_d = rx_irq_count_q;
  end

  always @(*) begin
    irq_fifo = 1'b0;
    rx_fifo_ren = 1'd0;
    rx_rstfifo = 1'd0;
    rx_finish_fifo_d = 1'd0;

    case(rx_state_cs)
      rx_IDLE: begin
        if(rx_irq_count_q == 7) begin
          rx_state_ns = rx_START;
        end
        else begin
          if (irq && rx_irq_count_q < 7) begin
            rx_finish_fifo_d = 1'd1;
          end
          else begin
            rx_finish_fifo_d = 1'd0;
          end
           
          rx_state_ns = rx_IDLE;
        end
      end
      rx_START: begin
        if(rx_irq_count_q == 0) begin
          rx_finish_fifo_d = 1'd1;
          rx_rstfifo = 1'd1;
          rx_state_ns = rx_IDLE;
        end
        else begin
          rx_fifo_ren = 1'd1;
          rx_state_ns = rx_IRQ;
        end
      end
      rx_IRQ: begin
        irq_fifo = 1'b1;
        rx_state_ns = rx_WAIT_READ;
      end
      rx_WAIT_READ: begin
        if(rx_finish)
          rx_state_ns = rx_START;
        else
          rx_state_ns = rx_WAIT_READ;
      end
    endcase
  end

// tx fifo
  // always @(*) begin
  //   if(tx_start) 
  //     tx_start_count_d = tx_start_count_q + 4'd1;
  //   else if(tx_start_clear)
  //     tx_start_count_d = tx_start_count_q - 4'd1;
  //   else 
  //     tx_start_count_d = tx_start_count_q;
  // end

  always @(*) begin
    tx_start_fifo = 1'd0;
    tx_clear_ren = 1'd0;
    tx_start_wen = 1'd0;
    tx_clear_fifo = 1'd0;
    tx_start_count_d = tx_start_count_q;
    tx_rstfifo = 1'd0;

    case(tx_state_cs)
      tx_IDLE: begin
        if(tx_start_count_q == 8) begin
          tx_state_ns = tx_START;
        end
        else if(tx_start) begin
          tx_start_wen = 1'd1;
          tx_start_count_d = tx_start_count_q + 4'd1;
          tx_state_ns = tx_FCLEAR;
        end
        else begin
          tx_state_ns = tx_IDLE;
        end
      end
      tx_FCLEAR: begin
        tx_clear_fifo = 1'd1;
        tx_state_ns = tx_IDLE;
      end
      tx_START: begin
        if(tx_start_count_q == 4'd0) begin
          tx_rstfifo = 1'd1;
          tx_state_ns = tx_IDLE;
        end
        else begin
          tx_start_fifo = 1'd1;
          tx_clear_ren = 1'd1;
          tx_state_ns = tx_CLEAR;
        end
      end
      tx_CLEAR: begin
        if(tx_start_clear) begin
          tx_start_count_d = tx_start_count_q - 4'd1;
          tx_state_ns = tx_START;
        end
        else
          tx_state_ns = tx_CLEAR;
      end
      default: tx_state_ns = tx_IDLE;
    endcase
  end
  // tx fifo

  always @(posedge wb_clk_i, posedge wb_rst_i) begin
      if (wb_rst_i) begin
          user_irq_q <= 0;
          irq_count_q <= 0;
          rx_irq_count_q <= 0;
          rx_state_cs <= 2'd0;
          tx_state_cs <= 2'd0;
          tx_start_count_q <= 4'd0;
          rx_finish_fifo_q <= 1'd0;
      end
      else begin
          user_irq_q <= user_irq_d;
          irq_count_q <= irq_count_d;
          rx_irq_count_q <= rx_irq_count_d;
          rx_state_cs <= rx_state_ns;
          tx_state_cs <= tx_state_ns;
          tx_start_count_q <= tx_start_count_d;
          rx_finish_fifo_q <= rx_finish_fifo_d;
      end
  end	
  

  // 32'h3000_0000 memory regions of user project  
  assign wb_valid = (wbs_adr_i[31:8] == 32'h3100_00) ? wbs_cyc_i && wbs_stb_i : 1'b0;

  wire [31:0] clk_div;
  assign clk_div = 40000000 / BAUD_RATE;

  uart_receive receive(
    .rst_n      (~wb_rst_i  ),
    .clk        (wb_clk_i   ),
    .clk_div    (clk_div    ),
    .rx         (rx         ),
    .rx_data    (rx_data    ),
    .rx_finish  (rx_finish_fifo_q  ),	// data receive finish
    .irq        (irq        ),
    .frame_err  (frame_err  ),
    .busy       (rx_busy    )
  );

  uart_transmission transmission(
    .rst_n      (~wb_rst_i  ),
    .clk        (wb_clk_i   ),
    .clk_div    (clk_div    ),
    .tx         (tx         ),
    .tx_data    (tx_data_fifo    ),//tx_data
    .clear_req  (tx_start_clear), // clear transmission request
    .tx_start   (tx_start_fifo ), //tx_start
    .busy       (tx_busy    )
  );
  
  ctrl ctrl(
	.rst_n		(~wb_rst_i),
	.clk		  (wb_clk_i	),
  .i_wb_valid(wb_valid),
	.i_wb_adr	(wbs_adr_i),
	.i_wb_we	(wbs_we_i	),
	.i_wb_dat	(wbs_dat_i),
	.i_wb_sel	(wbs_sel_i),
	.o_wb_ack	(wbs_ack_o),
	.o_wb_dat (wbs_dat_o),
	.i_rx		  (rx_data_fifo), //rx_data
  .i_irq    (irq_fifo ),
  .i_frame_err  (frame_err),
  .i_rx_busy    (1'b0 ), //rx_busy
	.o_rx_finish  (rx_finish),
	.o_tx		      (tx_data	),
	.i_tx_start_clear(tx_clear_fifo), 
  .i_tx_busy    (tx_busy  ),
	.o_tx_start	  (tx_start ) //to tx fifo w_en
  );

  synchronous_fifo 
  #(.DEPTH(9), .DATA_WIDTH(8))
  rx_fifo(
    .clk(wb_clk_i), 
    .rst(wb_rst_i),
    .w_en(irq), 
    .r_en(rx_fifo_ren),
    .data_in(rx_data),
    .data_out(rx_data_fifo),
    .full(rx_full), 
    .empty(rx_empty),
    .rstfifo(rx_rstfifo)
  );

  synchronous_fifo 
  #(.DEPTH(9), .DATA_WIDTH(8))
  tx_fifo(
    .clk(wb_clk_i), 
    .rst(wb_rst_i),
    .w_en(tx_start_wen), 
    .r_en(tx_clear_ren),
    .data_in(tx_data),
    .data_out(tx_data_fifo),
    .full(tx_full), 
    .empty(tx_empty),
    .rstfifo(tx_rstfifo)
  );
endmodule