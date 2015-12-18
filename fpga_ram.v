module fpga_ram(

input clk,  // 200MHz
input rst,
input ram_switch,

// this part of memory isn't using in the main module
input [7:0] tx_data_ram_addr,
output [31:0] tx_data_ram_data,

// send data memory
input [9:0] tx_data8_ram_addr,
output [7:0] tx_data8_ram_data,

// send frequency control memory
input [4:0] tx_freq_ram_addr,
output [31:0] tx_freq_ram_data,

// spread spectrum code memory
input [8:0] rx_code_ram_addr,
output[31:0] rx_code_ram_data,

//coarse synchronisation code register
input [8:0] correlate_code_address,
input [8:0] correlate_code_address_dual,
output [31:0] coarse_syn_code_data,
output [31:0] coarse_syn_code_data_dual,

// receive data memory
input [7:0] rx_data_ram_addr,
input [31:0] rx_data_ram_data,
input rx_data_ram_wr,

input rd_en,
input [7:0] rx_rd_addr,
output [31:0] rx_rd_data,
//input rx_rd_en,

// receive frequency control words memory
input [4:0] rx_freq_ram_addr_1,
input [4:0] rx_freq_ram_addr_2,
output [31:0] rx_freq_ram_data_1,
output [31:0] rx_freq_ram_data_2,

// frequency hopping number register 
output reg [31:0] fh_num

);

// send data memory
tx_data_ram	tx_data_ram_inst 
(
.address ( tx_data_ram_addr ),
.clock ( clk ),
.q ( tx_data_ram_data )
);

// 
tx_data8_ram	tx_data8_ram_inst 
(
.address ( tx_data8_ram_addr ),
.clock ( clk ),
.q ( tx_data8_ram_data )
);
	
// send frequency data memory
ram_tx_freq	ram_tx_freq_inst 
(
.address ( tx_freq_ram_addr ),
.clock ( clk ),
.q ( tx_freq_ram_data )

);

// spread spectrum code memory
rx_code_ram rx_code_ram_inst
(
.address( rx_code_ram_addr ),
.clock( clk ),
.q( rx_code_ram_data )
);

// 
// always @(posedge clk)
// begin
    // if(rst)
        // coarse_syn_code <= 32'h7CD215D8;
    // else
        // coarse_syn_code <= 32'h7CD215D8;
// end

//coarse synchronisation memory used for store coarse synchronisation head for testing.

// coarse_syn_code coarse_syn_code_inst
// (
		// .address(correlate_code_address[4:0]),
		// .clock(clk),
		// .q(coarse_syn_code_data)
// );


coarse_syn_cose_3ram coarse_syn_cose_3ram_inst
(
			.clock(clk),
			//.data(),
			.rdaddress_a(correlate_code_address[5:0]),
			.rdaddress_b(correlate_code_address_dual[5:0] + 6'd32),
			//.wraddress,
			//.wren,
			.qa(coarse_syn_code_data),
			.qb(coarse_syn_code_data_dual)
);

// used for setting the ping pong buffer structure
// wire rx_data_ram_wr_1,rx_data_ram_wr_2;//2 memories write enable
// wire rx_rd_en_1,rx_rd_en_2;            //2 memories read enable
// wire [31:0] rx_rd_data_1,rx_rd_data_2; //FPGA memory read-out values
// assign rx_data_ram_wr_1 = (ram_switch) ? rx_data_ram_wr  : 1'b0;
// assign rx_data_ram_wr_2 = (!ram_switch) ? rx_data_ram_wr : 1'b0;
// assign rx_rd_en_1  = (ram_switch) ? 1'b0 : 1'b1;
// assign rx_rd_en_2  = (!ram_switch) ? 1'b0 : 1'b1;
// assign rx_rd_data = (ram_switch) ? rx_rd_data_2 : rx_rd_data_1;

//for RTT 's consideration, the timeslot has to return data to DSP immediately so it can't use ping-pong buffer structure
rx_data_ram rx_data_ram_inst_1
(
.clock( clk ),
//.data( rx_data_ram_data ),
.rdaddress( rx_rd_addr),
.rden( rd_en ),
//.wraddress( rx_data_ram_addr ),
//.wren( rx_data_ram_wr ),
//.wren( 1'b0 ),
.q( rx_rd_data )

);


wire [31:0] rx_rd_data_test;

rx_data_test_ram rx_data_test_ram_inst
(
.clock( clk ),
.data( rx_data_ram_data ),
.address( rx_data_ram_addr ),
.wren( rx_data_ram_wr ),
.q( rx_rd_data_test )

);


// rx_data_ram rx_data_ram_inst_2
// (
// .clock( clk ),
// .data( rx_data_ram_data ),
// .rdaddress( rx_rd_addr),
// .rden( rx_rd_en_2 ),
// .wraddress( rx_data_ram_addr ),
// .wren( rx_data_ram_wr_2 ),
// .q( rx_rd_data_2 )

// );
//rx_ram_monitor rx_ram_monitor_inst
//(
//.address( rx_data_ram_addr),
//.clock( clk ),
//.data( rx_data_ram_data ),
//.wren( rx_data_ram_wr )
////.q( rx_rd_data )
//);


// ram_rx_freq	ram_rx_freq_inst
// (
// .address ( rx_freq_ram_addr ),
// .clock ( clk ),
// .q ( rx_freq_ram_data )

// );
//receiving frequency memory interface
rx_freq_three_port_test rx_freq_three_port_test_inst
(
.address_a(rx_freq_ram_addr_1),
.address_b(rx_freq_ram_addr_2),
.clock(clk),
.q_a(rx_freq_ram_data_1),
.q_b(rx_freq_ram_data_2)
);
// frequency hopping number register 
always @(posedge clk)
begin
    if(rst)
        fh_num <= 32'd904;    // the number of data one timeslot sends
    else
        fh_num <= 32'd904;
end

endmodule
