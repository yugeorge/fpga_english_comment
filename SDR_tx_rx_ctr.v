//***************************************************************************************************
//module name:SDR_tx_rx_ctr.v
//author:GYVVEI
//date:2012/10/21
//description:Through DSP transfer data to FPGA to control the state of FPGA in either send  or receive
//
//(1) Function Details
//     (1)from RAM0 read the TX,TL value  (2)the state switch between idle,receive and send  (3)read RAM4 and RAM5(Data,frequencies) deal with generated address
//
//(2) Basics:The whole module is running under the control of counter TOD. According TOD to do the responding state switch to relevant position
//            the period of TOD is a time slot.
//
//(3) Design besides state machine : system
//            TX_r       :      Message Begin Register
//            TL_r       :      Message Length Register
//            TX_begin  :      the start position of the send state (TX - 1)
//            TX_end    :      the end position of the send state    (TX + TL)
//
//(4) Design of state machine:
//      Receive->Send
//          when TL_r is not zero and TOD reach TX_begin , the state goes to receive
//      Send->Receive
//          When TOD arrives TX_end, the state goes to send.  
//*****************************************************************************************************

module SDR_tx_rx_ctr(
					input clk,                                  //80m to detect the necessary information
					input rst,    			                    //rst system initial reset
					
					input [20:0] tod_h,					        //timeslot counter module
					input [10:0] tod_l,                   
										
					input TEST_EN,
					
					output reg tx_rx_switch,					//Tx /Rx switch to control MCASP interface to send or to receive data				
					
					output reg[7:0] read_addr_0,                //read data from Tx and Tl to decide the state transfer of state machines.
					input read_ram0_en,
					input [31:0] read_data_0,
//					input	[31:0]    Tx,                       //the beginning point of the next timeslot sending message
//					input	[31:0]    Tl,                       //the length of message of the next timeslot
					
					input [9:0] data_addr_in,
					input [9:0] freq_addr_in,
					
					output reg[9:0] data_addr_out,
					output reg[9:0] freq_addr_out,
					
					output reg [31:0]  Tl_r,                    // the length of sending message in this timeslot
					output reg [15:0]  Tr,                       //Used for control the McBSP receiving interrupt
					output reg PTT,                             //Push to talk
					output reg AD_SHDN,							//AD SHDN control when work at the sending state turn off AD and open it at the receiving state.
					
					output reg led1								//Used for showing the state of RX/TX in system, at first it is blinking and TX for on and RX for off
					);
					
parameter sdr_idle = 3'b001;         //Power-up waiting for initialized
parameter sdr_rx   = 3'b010;         //terminal in  state of RX
parameter sdr_tx   = 3'b100;         //terminal in  state of TX
//control the transfer of the state machine(two segments)
reg [2:0] sdr_state; //Control of the whole SDR state machine


reg [31:0] Tx,Tl;               //the starting position of next time slot when sending message,the length of sending message
reg [9:0] Tx_r;
//reg [31:0] Tl_r;
reg [20:0] Tx_begin;            //the beginning point of sending state
reg [20:0] Tx_end;              //the ending point of sedning state

//Reading information from Tx and Tl
always@(posedge clk or posedge rst)
begin
	if(rst)
		begin
			read_addr_0 <= 8'd0;
		end
	else
		begin
			if(read_ram0_en)
				begin
					read_addr_0 <= read_addr_0 + 8'd1;
					if(read_addr_0 == 8'd10)
						begin
							read_addr_0 <= read_addr_0;
						end
				end
			else
				begin
					read_addr_0 <= 8'd0;
				end
		end
end

always@(posedge clk or posedge rst)
begin
	if(rst)
		begin
			Tx <= 32'd0;
			Tl <= 32'd0;
		end
	else
		begin
			if(TEST_EN)
				begin
					Tl <= 32'hFFFF0380;   //This value is used for testing the whole system without DSP
					Tx <= 32'h03800000;
				end
			else
				begin
					if(read_ram0_en)
						begin
							case(read_addr_0)
						9'd2:  Tl <= read_data_0;                        
						9'd5:  Tx <= read_data_0;		    
							endcase
						end
					else
						begin
							Tx <= Tx;
							Tl <= Tl;
						end
				end
		end
end

//the transfer part of the state machine
always@(posedge clk or posedge rst)
	begin
		if(rst)
			begin
				sdr_state <= sdr_idle;
				Tx_r <= 10'd0;
				Tl_r <= 32'd0;
				Tr   <= 16'd0;
				Tx_begin <= 21'd0;
				Tx_end <= 21'd0;				
			end
		else
			begin
			    
				if((tod_h == 21'd975) && (tod_l == 11'd0))              //at the last but two load four register to ram and to use it at the next time slot.
				    begin
					    Tx_r <= Tx[9:0];
						Tl_r <= Tl;
						Tr   <= Tx[31:16];
						
						if (Tx[9:0] == 10'd0)                                //the beginning position of sending state
						    Tx_begin <= 21'd976;
						else
						    Tx_begin <= Tx[9:0] - 21'd1; 
						
						Tx_end <= Tx[9:0] + Tl[9:0];                    //the ending position of sending state
					end
				else
				    begin 
					    Tx_r <= Tx_r;
						Tl_r <= Tl_r;
						Tr   <= Tr;
						Tx_begin <= Tx_begin;
						Tx_end <= Tx_end;
					end
					    
				case(sdr_state)
			sdr_idle:
				begin
					if(Tl_r[31:16] == 16'hffff)      //this symbol proves that the initial process has finished and it can 
						begin
							if(Tl_r[15:0] == 16'h0) //next timeslot is the receive timeslot
								begin
									sdr_state <= sdr_rx;
								end
							else
								begin
									if((tod_h == 21'd976) && (tod_l < 11'd449))          //open 4.5us in advance next timeslot is sending timeslot.
										begin
											sdr_state <= sdr_idle;         
										end
									else
										begin
											sdr_state <= sdr_tx;			//after the first power-up it enters next sending state but the corresponding PTT has opened 4.5us in advance.
										end
								end
						end
					else
						begin
							sdr_state <= sdr_idle;
						end				
				end
			sdr_rx:
				begin

					if(Tl_r[15:0] == 16'h0)			                          //the length of sending message (it updates at the timeslot)
						begin	
							sdr_state <= sdr_state;
                        end
					else
						if((tod_h == Tx_begin) && (tod_l == 11'd0))          //when the sending length is nor zero, go into the sending state at Tx_begin
						    begin
							    sdr_state <= sdr_tx;
						    end
					    else
						    begin
							    sdr_state <= sdr_state;
						    end
				end
			sdr_tx:
				begin
				
					if((tod_h == Tx_end) && (tod_l == 11'd0))              //state transfer is determined at the end of this timeslot 
						begin
							sdr_state <= sdr_rx;
						end
					else
						begin
							sdr_state <= sdr_state;	
						end
					
				end
			default:
				begin
					sdr_state <= sdr_idle;	
				end
				endcase
			end
	end

//the output part of the state machine

always@(posedge clk or posedge rst)
	begin
		if(rst)
			begin
			    tx_rx_switch <= 1'b0;
				PTT <= 1'b0;
                AD_SHDN <= 1'b0;
				data_addr_out <= 10'd0;			
                freq_addr_out <= 10'd0;				
			end
		else 
			begin
			case(sdr_state)
		sdr_idle:
					begin
			            tx_rx_switch <= 1'b0;
				        PTT <= 1'b0;
                        AD_SHDN <= 1'b0;
				        data_addr_out <= data_addr_in;			
                        freq_addr_out <= freq_addr_in;							    
					end
		sdr_rx:		
					begin
			            tx_rx_switch <= 1'b0;
				        PTT <= 1'b0;
                        AD_SHDN <= 1'b0;
				        data_addr_out <= data_addr_in;			
                        freq_addr_out <= freq_addr_in;							
					end
		sdr_tx:
					begin
			            tx_rx_switch <= 1'b1;
				        PTT <= 1'b1;
                        AD_SHDN <= 1'b0;
				        data_addr_out <= data_addr_in - Tx_r;			
                        freq_addr_out <= freq_addr_in - Tx_r;							
					end
			endcase
			
			end
				
	end

//--------------------------------------------------------------------------
//				part of monitoring the program,used for detecting the normal state of the system 
//--------------------------------------------------------------------------
reg [25:0] led_cnt;									//counter of frequency dividing,flash light to 1 second
always@(posedge clk or posedge rst)
	begin
		if(rst)
			begin
				led1 <= 1'b1;
				led_cnt <= 26'd0;
			end
		else 
			begin
			case(sdr_state)
		sdr_idle:
					begin
					if(led_cnt == 26'd20000000)
						begin
							led_cnt <= 26'd0;
							led1 <= ~led1;
						end
					else
						begin
							led_cnt <= led_cnt +26'd1;
						end
					end
		sdr_rx:		
					begin
						led_cnt <= 26'd0;
						led1 <= 1'b1;
					end
		sdr_tx:
					begin
						led_cnt <= 26'd0;
						led1 <= 1'b0;
					end
			endcase
			
			end
			
	
	end
//------------------------------------------------------------------------
endmodule 