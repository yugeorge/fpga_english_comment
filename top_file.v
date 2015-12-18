//Topfile that controls all of the modules
//



module top_file(	
			
// reference clk 25M
			input clk_ref,     
			//input rst,
			
// McBSP interface			
			input  dr,                 
			output dx,
			input  de_bit_first,
			input  clkx,                
			input  fsx,                 
			output fsr,
			output clkr,
			output int_rx,			//FPGA ready to receive data from DSP so send to DSP an interrupt
			output int_rx_test,
			output int_tx_ctr, 		//FPGA ready to send data to DSP so send to DSP an interrupt
			output ahclkx, 	   		//clks send to DSP 20M
			output int_tx_test,
			
//DSP spi interface(slave pattern)
			output int_spi,         //SPI interrupt
			output int_spi_test,
			input  DSP_cs,
			input  DSP_mosi,
			input  DSP_sck,
			output DSP_miso,	
			
			output de_bit_out,
			output de_bit,
			
//ADS6148 system configuration
	
	//		input ad_sout,
	//		input ad_clkout,
	//		output ad_oe,
	//		output ad_clk,
	//		output ad_rst,
	//		output ad_sclk,
	//		output ad_sdata,
	//		input[6:0]ad_data_primer,
			
//AD9957 interface
//			output [17:0] DA,
//			input  DA_PDCLK,
//			input  DA_CCI_OF,
//			input  DA_REF_CLK_OUT,
//			output [2:0] profile_sel,
//			input  DA_PLL_LOCK,
//			output DA_IO_UPDATA,   //this pin can be configured as both input and output
//			output DA_IO_rst,
//			output DA_EXT_PWR_DWN,
			input  DA_SYNC_clk,
//			output TxENABLE,
//			output DA_RT,
//			output MREST,          //system reset
//			output sck,
//			output cs,
//			output sdio,
//			input  sdo,
//			output DA_CS,
//			output pwm,
			
//??????			
			output PTT,
//testing signal
		    output led1,
			output led2,
			// output led3,
			output coarse_flag,
			output fine_flag,
		//	output clk_not_accurate,

			output de_bit_out_test,
			output tod_flag,
			output coarse_syn_success,
			output flag_begin,
			output rd_en,
			output fsr_test,
		//	output clkr_test,
			output read_fh_num_en,	//????DSP?FPGA??MCASP?????????
			output clk_25m,
//FPGA????
	
			input test_mode,
			output test_mode_dsp, 	//??DSP
			
//????
         output clk_200m_DA,
         output bit_in,
			output spi_clk2
	//		output fine_syn_flag
			
			

			
);
////////////////////////////////////????//////////////////////////////////////////////////////////////
//test FPGA and DSP interrupt pin
//wire bit_in;
wire rx_position;
assign int_rx_test   =  (tx_rx_switch) ? bit_in : 1'b0;
assign int_spi_test  =  int_spi;
// assign int_tx_test   =  ~led1;
assign led2 = coarse_flag;
assign int_tx_test   =  rx_position;
assign fsr_test      =  coarse_syn_success;
//assign clkr_test     =  rx_syn_test;         //C1????
assign clk_25m = clk_25m_ref;
assign spi_clk2    =  1'b0;

//---------------------------------------------------------------------------------------------------------------------------
//        					PLL???????AD,DA?????????????????????????? 
//---------------------------------------------------------------------------------------------------------------------------
//SI550??AD9957?????????????????????PWM????
wire clk_10m_DA, clk_100m_DA, clk_25m_DA,clk_50m_DA;
wire clk_2m_ref;
//pll_clk?pll_clk2?800M??????200M????FPGA??????????????DA?????
pll_clk	pll_clk_inst (
                
                .inclk0 ( DA_SYNC_clk ),    // 200MHz     
                .c0 ( clk_10m_DA ),         // 10MHz          \
                .c1 ( clk_50m_DA ),         // 50MHz ??90閿熸枻鎷  \   ?????????????
                .c2 ( clk_100m_DA ),         // 100MHz           /
                .c3 ( clk_25m_DA ),         // 25MHz          /
                .c4 ( clk_200m_DA)          //200MHZ               DSP?FPGA??MCASP?????
                );


//wire clk_not_accurate;
pll_clk_2 pll_clk_2_inst(
				.inclk0(DA_SYNC_clk),  //200M
				.c0(ahclkx),           //20M???DSP?????
	//			.c1(clk_not_accurate)  //????25M??
	         .c1(clk_160m_AD),
				);	
				
//pll_clk3???25M???????????????AD?????
wire clk_100m_ref , clk_25m_ref,  clk_80m_AD;				
pll_clk_3  pll_clk_3_inst(
						.inclk0(clk_ref),  //25m
			//			.c0(ad_clk),       //200m    ??AD????
						.c1(clk_2m_ref),   //2m      ?????????AD9957
						.c2(clk_100m_ref), //100m    ??PWM????
						.c3(clk_25m_ref)   //50m     ????PWM??
//						.c4(clk_80m_AD)
						);

// ad_pll?LTC2209????AD??????????????????????????
wire clk_160m_AD , clk_200m_AD , clk_10m_AD;
//ad_pll ad_pll_inst(
//				.inclk0(ad_clkout),    // AD 160m????
//				.c0(clk_160m_AD),       //???160m????
//				.c1(clk_10m_AD),         //??FPGA?DSP???????????clkr?10M??
//				.c2(clk_200m_AD),
//				.c3(clk_80m_AD)
//					);
//assign clkr = clk_10m_AD;
  assign clkr = clk_10m_DA;
//--------------------------------------------------------------------------
//                                System initialization
//--------------------------------------------------------------------------
wire rst;              
SYS_Initial SYS_Initial_inst(	
              .clk( clk_ref ),
              .rst( rst )
					 ); 

//--------------------------------------------------------------------------
//                              ADS6148 configuration
//--------------------------------------------------------------------------
//assign ad_oe = 1'b1;
//assign ad_rst = 1'b1;
//assign ad_sclk = 1'b0;
//assign ad_sdata = 1'b0;


//wire [15:0] ad_data_reg;
//ad_data_out ad_data_out_inst(
//				.clk_ad(ad_clkout),
//				.rst(rst),
//				.ad_data_pri(ad_data_primer),
//				.ad_data(ad_data[15:2])
//);
//wire [15:0]ad_data;
//assign ad_data = ad_data_reg - 8'd128;
//assign ad_data = {ad_data_reg[13],ad_data_reg[4:0],10'd0}; 
//--------------------------------------------------------------------------
//						 AD9957 initialization and corresponding settings
//--------------------------------------------------------------------------
//------------------------------------------		
//AD9957????
//--------------------------
//assign DA_IO_rst = 1'b0;        //connect to ground so it can be invalid permantly
//assign DA_EXT_PWR_DWN = 1'b0;
//assign DA_RT = 1'b0;
//assign DA_CS = 1'b0;
//assign MREST = 1'b0;
//assign profile_sel = 3'b000;
//--------------------------
//??AD9957????AD9957???????AD9957?????????????????
//(1) ????????????????????????sys_initial?????????????
//(2) ?????????????AD9957?????????TXENABLE????????CCI???
//(3) ??IO_UPDATA ? PROFILE[3:0]??????????????profile????IO_UPDATA??????
(*keep*) wire [31:0] freq_factor;
//(*keep*) wire freq_factor_en;
//wire initial_end;//????????????????????????
//wire flag;	
//wire initial_sck,initial_cs,initial_sdio,initial_io_updata;
//wire config_sck,config_cs,config_sdio,config_io_updata;
//AD9957?????3????
//AD9957_initial AD9957_initial_inst(
//						            .clk(clk_2m_ref),                   
//									.rst(rst),                   
//									
//									.sck(initial_sck),                  
//									.cs(initial_cs),
//									.sdio(initial_sdio),
//									
//									.DA_IO_UPDATA(initial_io_updata),     
//									.initial_end(initial_end)       
//);

//??????											
//AD9957_config AD9957_config_inst(
//									.clk(clk_10m_DA),                  
//									.rst(rst), 
//									.FTW_en(freq_factor_en),
//									.freq_factor(freq_factor),
//									
//									.sck(config_sck),                  
//									.cs(config_cs),
//									.sdio(config_sdio),
//									
//									.led3(led3),            
//									.flag(flag),
//									.DA_IO_UPDATA(config_io_updata)  
//);

//assign sck           =  (initial_end) ?  initial_sck : config_sck;
//assign cs            =  (initial_end) ?  initial_cs  : config_cs;
//assign sdio          =  (initial_end) ?  initial_sdio: config_sdio;
//assign DA_IO_UPDATA  =  (initial_end) ?  initial_io_updata :config_io_updata;

//-----------------------------------------------------------------------------------------------
//						PWM module
//                    ????EP3C40??????????0.5-1.5PPM????????????
//-----------------------------------------------------------------------------------------------
/* PWM_top_file PWM_top_file_inst(
		             .rst(initial_end),
		             .clk_not_accurate(clk_not_accurate),//25M
		             .clk_ref_100M(clk_25m_ref),        //25M
					 .clk_50M(clk_25m_ref),
					 .pwm(pwm)
); */
//----------------------------------------------------------------------------------------
//								??????????
//----------------------------------------------------------------------------------------
wire [20:0]  tod_h;
wire [10:0]  tod_l;
wire [7:0] 	 read_addr_0;

wire [31:0] read_data_0;
wire tx_rx_switch;
wire [31:0] Tl_r;
wire [15:0] Tl_rx;
SDR_tx_rx_ctr SDR_tx_rx_ctr_inst(
								.clk(clk_100m_DA),                                  //100m??????????????
						//		.rst(initial_end),    			                   //???????????rst
						     	.rst(rst),  
								.tod_h(tod_h),					                   //???????????PTT??????
								.tod_l(tod_l),
								
								//.TEST_EN(TEST_EN),
								.TEST_EN(1'b1),
								.tx_rx_switch(tx_rx_switch),
								
								.read_addr_0(read_addr_0),
								.read_ram0_en(read_fh_num_en),
								.read_data_0(read_data_0),
//								.fh_num_next_slot(fh_num_next_slot),         	   //?????????
//								.fh_num_cur_slot(fh_num_cur_slot),                 //????????????????????????fh_num_cur_slot

                                .data_addr_in(tx_data_ram_addr),
								.freq_addr_in(tx_freq_ram_addr),
								.data_addr_out(tx_data_ram_addr_t),
								.freq_addr_out(tx_freq_ram_addr_t),
								
								.Tl_r(Tl_r),
								.Tr(Tl_rx),
								.PTT(PTT),                                         //?????? 
								.AD_SHDN(AD_SHDN),
								.led1(led1)										   //???????????
								);
//assign int_tx_ctr = (tx_rx_switch) ? 1'b0 : int_tx;
  assign int_tx_ctr = int_tx;

//assign fsr=fsx;
//assign dx=dr;
//--------------------------------------------------------------------------
//                         FPGA?????
//--------------------------------------------------------------------------
wire [9:0] tx_data_ram_addr,tx_data_ram_addr_t;
wire [31:0] tx_data_ram_data; 

wire [9:0] rd_addr;
wire [7:0] tx_data8_ram_data; 

wire [9:0] tx_freq_ram_addr,tx_freq_ram_addr_t;
wire [31:0] tx_freq_ram_data_ram;

wire [8:0] rx_code_ram_addr;
wire [31:0] rx_code_ram_data;


wire [7:0] rx_data_ram_addr;
wire [31:0] rx_data_ram_data;
wire rx_data_ram_wr;

wire [9:0] rx_rd_addr;
wire [31:0] rx_rd_data;
wire rx_rd_en;

wire [9:0]  rx_freq_ram_addr_1;
wire [31:0] rx_freq_ram_data_1_ram,rx_freq_ram_data_1;
wire [9:0]  rx_freq_ram_addr_2;
wire [31:0] rx_freq_ram_data_2_ram,rx_freq_ram_data_2;

//wire [31:0] fh_num;
wire time_slot_data_en;
wire ram_read_en;
wire [7:0] read_address;
wire clk_160m;

//wire [7:0] tx_data_ram_index;  // ?????????
//wire [7:0] tx_freq_ram_addr_index;  // ????????
//wire [7:0] rx_freq_ram_addr_index1,rx_freq_ram_addr_index2; //?????????????
 
fpga_ram fpga_ram_inst(

                      .clk( clk_200m_DA ),
					 //    .clk( clk_200m_AD ),    // 160MHz
               //     .rst( initial_end ),
					      .rst(rst),
					//.ram_switch(fine_flag),//?????????

                    // ???????
//                     .tx_data_ram_addr( tx_data_ram_index[7:0] ),
//                     .tx_data_ram_data( tx_data_ram_data ),
                    
                    .tx_data8_ram_addr( rx_rd_addr ),
                    .tx_data8_ram_data( tx_data8_ram_data ),

                    // ???????
//                      .tx_freq_ram_addr( tx_freq_ram_addr_index[4:0] ),
//                      .tx_freq_ram_data( tx_freq_ram_data_ram ),

                    // ????????
                    .rx_code_ram_addr( rx_code_ram_addr ),
                    .rx_code_ram_data( rx_code_ram_data ),

                    // ???????
                    .rx_data_ram_addr( rx_data_ram_addr ),
                    .rx_data_ram_data( rx_data_ram_data ),
                    .rx_data_ram_wr( rx_data_ram_wr ),
                    .rd_en(rd_en),						//?????????????????????
                    .rx_rd_addr( read_address ),
                    .rx_rd_data( rx_rd_data ),

                    // ???????
                    // .rx_freq_ram_addr( rx_freq_ram_addr ),
                    // .rx_freq_ram_data( rx_freq_ram_data ),
//					.rx_freq_ram_addr_1(rx_freq_ram_addr_index1[4:0]),
//					.rx_freq_ram_addr_2(rx_freq_ram_addr_index2[4:0]),
//					.rx_freq_ram_data_1(rx_freq_ram_data_1_ram),
//					.rx_freq_ram_data_2(rx_freq_ram_data_2_ram),
                    
					// ??????
//                    .fh_num( fh_num )

                    );

//--------------------------------------------------------------------------
//                            ??????? 
//--------------------------------------------------------------------------  
//assign rx_freq_ram_data_1 = (!tx_rx_switch) ? rx_freq_ram_data_1_ram: 32'd0;
//assign rx_freq_ram_data_2 = (!tx_rx_switch) ? rx_freq_ram_data_2_ram: 32'd0;
assign rx_freq_ram_data_1 = rx_freq_ram_data_1_ram;
assign rx_freq_ram_data_2 = rx_freq_ram_data_2_ram;
wire fine_syn_success;
wire transform_en;
wire tx_flag;
wire tx_begin;
wire fine_syn_flag;
rx_iq rx_iq_inst(

            //    .rst( initial_end ),
                .rst(rst),				
			   //	.ad_data( ad_data ),
				//.clk_200m(clk_200m_AD),
				.clk_200m(clk_200m_DA),
				.clk_160m(clk_160m_AD),
				.tx_flag(tx_flag),
				.tx_begin(tx_begin),
            .de_bit_first(de_bit_first),
            .de_bit_out( de_bit_out ),
				.de_bit(de_bit),
                .coarse_syn_success( coarse_syn_success ),
                .fine_syn_success( fine_syn_success ),

                // ??????
                .rx_code_ram_addr( rx_code_ram_addr ),
                .rx_code_ram_data( rx_code_ram_data ),
				
                // ???????
                .rx_data_ram_addr_t( rx_data_ram_addr ),
                .rx_data_ram_data_t( rx_data_ram_data ),
                .rx_data_ram_wr_t( rx_data_ram_wr ),

                // ???????
                // .rx_freq_ram_addr( rx_freq_ram_addr ),
                // .rx_freq_ram_data( rx_freq_ram_data ),
				
				.rx_freq_ram_addr_1(rx_freq_ram_addr_1),
				.rx_freq_ram_data_1(rx_freq_ram_data_1),
				.rx_freq_ram_addr_2(rx_freq_ram_addr_2),
				.rx_freq_ram_data_2(rx_freq_ram_data_2),
				
				//??MSK????
				.de_bit_out_test(de_bit_out_test),

                // ??????? 
                .Tl_r( Tl_rx ),									//???????????
				.time_slot_data_en(time_slot_data_en),
				.coarse_flag(coarse_flag),
				.fine_flag(fine_flag),
				.fine_syn_flag(fine_syn_flag),
				
				.tod_h(tod_h),										//??????????DSP?TOD????
				.tod_l(tod_l),
				.rx_position(rx_position)
                );
//----------------------------------------------------------------------------------------
//                                      ?????
//----------------------------------------------------------------------------------------				
//????????????????????????160M??????80M???????????
//????????????
reg syn_success;
always@(posedge clk_200m_AD or posedge rst)
	begin
		if(rst)
			begin
			     syn_success <= 1'b1;
			end
		else
			begin
				if(fine_syn_flag)
					syn_success <= ~syn_success;	
				else
					syn_success <= syn_success;
			end
	end

//????????
reg q1,q2;//????????
reg q3;   //??????????????	
always@(posedge clk_100m_DA or posedge rst)
	begin
		if(rst)
			begin
				q1 <= 1'b0;
				q2 <= 1'b0;
				q3 <= 1'b0;
			end
		else
			begin
				q1 <= syn_success;
				q2 <= q1 ;
				q3 <= q2;
			end
	
	end
wire syn_success_flag;   //????tx?TOD??????
assign 	syn_success_flag = q3 ^ q2;
	
//--------------------------------------------------------------------------
// ??????? 
//-------------------------------------------------------------------------- 
wire time_slot_flag;
 tx_top tx_top_inst(

					 .clk(clk_100m_DA),                      // 80MHz,?80M??????DA????????????????????80M??????????????DA???
					 .clk_25m(clk_25m_DA),                  // 25MHz
					 .clk_50m(clk_50m_DA),
					 .clk_200m(clk_200m_DA),
					// .PDCLK(DA_PDCLK),
					// .rst(initial_end),
					  .rst(rst),
					// .flag(flag),


					// .Txenable(TxENABLE),
					// .data_out(DA),
					 .tod_flag(tod_flag),

					 .bit_in(bit_in),

					 .send_data_ram_addr(tx_data_ram_addr),
					 .send_data_ram_data(tx_data_ram_data),

					 .freq_ram_addr(tx_freq_ram_addr),
					 .freq_ram_data(tx_freq_ram_data),

					 .fh_num(Tl_r),               // ????????

					 .freq_factor(freq_factor),
					// .freq_factor_en(freq_factor_en),
					 .syn_success(syn_success_flag),
					 .time_slot_flag(time_slot_flag),
					 .tod_h(tod_h),
					 .tod_l(tod_l)
 );				
//??????
wire int_tx;
wire spi_rx_ram_UART_read_en;
wire [8:0] UART_LVDS_address;
wire [15:0] UART_DATA;
wire [8:0] spi_read_address_UART;
wire [15:0] spi_read_data_out_UART;
wire [31:0] tx_data_in;

//?????????????
// wire [8:0] read_address_2_1  =  (tx_rx_switch) ? (tx_freq_ram_addr[8:0]) :(rx_freq_ram_addr_1[8:0]) ;
// wire [8:0] read_address_2_2  =  (tx_rx_switch) ? 9'd0 :(rx_freq_ram_addr_2[8:0]) ;
// wire [31:0]  data_output_2_1,data_output_2_2;

wire [31:0] tx_freq_ram_data  = (tx_rx_switch) ? tx_freq_ram_data_ram : 32'd0 ;//
//wire [31:0] tx_freq_ram_data  = 32'h4CCCCCCC;

// assign rx_freq_ram_data_1 = (!tx_rx_switch) ? data_output_2_1 : 32'd0;
// assign rx_freq_ram_data_2 = (!tx_rx_switch) ? data_output_2_2 : 32'd0;

// assign tx_data_in = (tx_data_switch) ? ({tod_h,tod_l}): rx_rd_data ;
assign tx_data_in = rx_rd_data ;
test_transform test_transform_inst(
								.clk_100m(clk_100m_DA),   //100M
								.clk_200m(clk_200m_DA),
					  
								.clkr(clkr),   //10M clkr clock signal
						//		.rst(initial_end),
						      .rst(rst),
								
								.dr(dr),
								.dx(dx),
								
								.clkx(clkx),
								.fsr(fsr),   //??clkx?????????6747?????

								

								.fsx(fsx),
								
								.int(int_rx),    		//receive data interrupt
							//	.int_tx(int_tx), 		//send data interrupt
								.int_tx_all(int_tx),
								.int_spi(int_spi),
								
								.transform_en(transform_en),
								
								
								.cs(DSP_cs),
								.mosi(DSP_mosi),
								.sck(DSP_sck),
								.miso(DSP_miso),
								
//test_transform????????9??????????????
								.read_address_0({1'b0,read_addr_0}), 
								.read_addr_4(tx_freq_ram_addr_t),			 // ??????????
								.read_addr_4_1(rx_freq_ram_addr_1),      // ??????????
								.read_addr_4_2(rx_freq_ram_addr_2),
								.read_addr_5(tx_data_ram_addr_t),          // ???????

								
								.data_output_0(read_data_0),		    // ?fh_num?????????				
								.data_output_1(tx_data_ram_data),
								.data_output_2(tx_freq_ram_data_ram),
								.data_output_3_1(rx_freq_ram_data_1_ram),
								.data_output_3_2(rx_freq_ram_data_2_ram),
								
								.tx_rom_address(read_address),				//MCASP??????
								.tx_data_in(tx_data_in),	//32bit
								.tx_flag(tx_flag),
								.tx_begin(tx_begin),
								.time_slot_flag(time_slot_flag),
								.rd_en(rd_en),								//MCASP???????????FPGA_RAM???
								.flag_begin(flag_begin),
								.read_fh_num_en(read_fh_num_en),
								.tx_data_switch(tx_data_switch),
//UART_LVDS????
								.spi_read_address_UART(spi_read_address_UART),
								.spi_read_data_out_UART(spi_read_data_out_UART),								
								.spi_rx_ram_UART_read_en(spi_rx_ram_UART_read_en),
								.UART_LVDS_address(UART_LVDS_address),
								.UART_DATA(UART_DATA),
								.power_ctr_en(power_ctr_en),
								.channel_fading_en(channel_fading_en)
	
);
//-----------------------------------------------------------------------------------
//							 System indication module, indicate that AD9957 is working properly
//-----------------------------------------------------------------------------------


//led led_inst(
//			.DA_PDCLK(DA_PDCLK),   //50M
//			.clk_test(clk_50m_DA), //50M
//			.freq_factor_en(freq_factor_en),
//			.rst(rst),
//			
//			//.led1(led2)
////			.led2(led2)				//AD9957 DAPDCLK?????
//			//.led3(led3)
//
//			);
//-----------------------------------------------------------------------------------
//???????????200M
//wire [31:0] tx_sys_count,rx_sys_count;
//wire rx_syn_test;
//sys_clk_test sys_clk_test_tx(
//    .clk(clk_200m_DA),    //200m
//	.rst(initial_end),
//	.flag(time_slot_flag),
//	  
//	.sys_count(tx_sys_count)
//);
//???????????200M
//sys_clk_test_rx sys_clk_test_rx_inst(
//    .clk(clk_200m_DA),    //200m
//	.rst(initial_end),
//	.flag(syn_success_flag),
//	.ts_flag(time_slot_flag),
//	  
//	.sys_count(rx_sys_count),
//	.rx_syn_test(rx_syn_test)
//);


//??????

wire TEST_EN;
wire test_soft;

TEST_CON TEST_CON_inst
(
	.result(test_soft)
);

assign TEST_EN = test_soft | (~test_mode) ;

assign test_mode_dsp = test_mode;


endmodule
