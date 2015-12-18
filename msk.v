module msk(

input  clk_25m,     // 25MHz
input  clk_50m,
input  clk_100m,
input  clk_200m,
input  PDCLK,        // AD9957 input clk

input  rst,
input  time_slot_flag,
input  bit_in,      // bit in to be modulated
input  flag,
output [17:0] data_out,           //the parrallel 18bit data that send to AD9957
output Txenable                   //the data send enable signal that sends to AD9957

);

//--------------------------------------------------------------------------
// MSK baseband modulation module, data rate at 25MSPS
//--------------------------------------------------------------------------
wire [17:0] baseband_I, baseband_Q;

gmsk_baseband_mod_25m gmsk_baseband_mod_25m_inst
(

            .clk_25m( clk_25m ),
			.clk_100m(clk_100m),
			.clk_200m(clk_200m),
            .rst( rst ),

            .bit_in( bit_in ),
            .time_slot_flag(time_slot_flag),
            .baseband_I( baseband_I ),
            .baseband_Q( baseband_Q )

            );
//--------------------------------------------------------------------------
//	to AD9957  IQ timing control module AD9957 timing control
//--------------------------------------------------------------------------

tx_IQ_timing_ctr tx_IQ_timing_ctr_inst(
						.clk_25M(clk_25m),//clk divider
						.clk_200m(clk_200m),
						.PDCLK(PDCLK),  //AD9957 data clk AD9957 input data rate 50Msps
						.rst(rst),    //system reset
						.baseband_I(baseband_I),//18bit
						.baseband_Q(baseband_Q),
						.flag(flag),
						.data_out(data_out),
						.Txenable(Txenable)					
				);

endmodule
