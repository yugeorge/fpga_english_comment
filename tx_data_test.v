//*******************************************************************************
//module name:tx_data_test.v
//Author:IVAN
//Date:2011/1/6

//Revised by:George Yu
//Date:2015/12/12

//Function Description : from ROM continue read data and send them to mcasp 
//*******************************************************************************
module tx_data_test(
				input clkr,   //10m clk
				input rst,   
				
				input int,                //interrupt signal, used for ensuring the actual data transfer position
				input int_begin,
				input tx_ready,			  //data send enable signal,generate once every 32bit data
				output reg rd_en,         //read enable signal of sending RAM
				// output [31:0] tx_data, //32bit data to send
				output reg tx_data_en,
				output reg [7:0] rom_address,
				output reg flag_begin,
				output reg tx_data_switch,
				output reg [13:0] time_count, //this counter is used for generating the sending interrupt of every 864 data transfer to DSP
				output reg int_tx_all
					);


reg flag;
always@(posedge clkr or posedge rst)
	begin
		if(rst)
			flag <= 1'b0;
		else
			begin
				if(!int)
					flag <= 1'b1;
				else
					flag <= 1'b0;
			end
	end

//counter adding delays after the interrupt	
reg[9:0] cnt;
reg cnt_state;
//reg [9:0] time_count;
//reg flag_begin;
always@(posedge clkr or posedge rst)
	begin
		if(rst)
			begin
				cnt <= 10'd0;
				flag_begin <= 1'b0;
				cnt_state <= 1'b0;
			end
		else
			begin
					case(cnt_state)
				0:begin
					flag_begin <= 1'b0;
					if(flag)
						cnt_state <= 1'b1;
					else
						cnt_state <= 1'b0;
				  end
				1:begin
						if(cnt == 10'd512)
							begin
								flag_begin <= 1'b1;
								cnt <= 10'd0;
								cnt_state <= 1'b0;
							end
						else
							begin
								cnt <= cnt + 10'd1;
							end
				  end
				  endcase
			end
	end	

reg[2:0] state;   	   //add more states,send a 32bit value of TOA before sending data from the receiving memory officially	
reg[7:0] add_cnt;
//reg[7:0] rom_address;//256 datas, ROM address					
always@(posedge clkr or posedge rst)
	begin
		if(rst)
			begin
				rom_address <= 8'd0;
				state <= 3'd0;
				tx_data_en <= 1'b0;
				rd_en <= 1'b0;
				tx_data_switch <= 1'b0;
				add_cnt <= 8'd0;
			end
		else
			begin	
				case(state)
			0:	begin
					tx_data_en <= 1'b0;
					add_cnt <= 11'd0;
					rom_address <= 8'd0;
//					if(rom_address==8'd0)
//						begin
//							time_count<=time_count+10'd1;
//						end
					if(flag_begin)
						begin
							rd_en <= 1'b0;
							state <= 3'd1;
						end
					else
						begin
							state <= 3'd0;
							rd_en <= 1'b0;
						end
				end
				
			1:	begin
					tx_data_en <= 1'b1;
					tx_data_switch <= 1'b1;	
					if(rom_address==8'd0)
						begin
							time_count<=14'd0;
							//tx_data_en<=1'b0;
						end
				//	else
				//		begin
				//			tx_data_en<=1'b1;
				//		end
					
					//the switch of sending data,using this switch control to decide whether to send value of TOA or to send data from the receiving memory.
					if(tx_ready)
						begin
							tx_data_switch <= 1'b0;
							rd_en <= 1'b1;
							state <= 3'd2;
//							rom_address <= rom_address +8'd1;
						end
				end
				
			2:  begin
				//	tx_data_en <= 1'b1;
			  		if(tx_ready)
						begin
							if(add_cnt == 8'd22)   //to send 216*32bit data
								begin
									rom_address <= rom_address;
									add_cnt <= 8'd0;
									state <= 3'd3;
									rd_en <= 1'b0;
								end
							else
							    begin
								    rom_address <= rom_address +8'd1;
									add_cnt <= add_cnt + 8'd1;
								end
						end
					else
						rom_address <= rom_address;
			  end
			3:	begin
					tx_data_en <= 1'b0;
					add_cnt <= 6'd0;
					rom_address <= rom_address;
					if(rom_address==8'd214)
					 begin
						time_count<=time_count+14'd1;
						if(time_count==14'd300)
							begin
							  int_tx_all<=1'b0;
							end
						if(time_count==14'd14850)
						 begin
							int_tx_all<=1'b1;
						 end
					 end
					 
					if(int_begin)
						state <= 3'd0;
					else		
					if(flag_begin)
						begin
							rd_en <= 1'b1;
							state <= 3'd4;
							rom_address <= rom_address +8'd1;
						end
					else
						begin
							state <= 3'd3;
							rd_en <= 1'b0;
							rom_address <= rom_address;
						end
				end
			4:  begin
					tx_data_en <= 1'b1;
					
			  		if(tx_ready)
						begin
				            if(rom_address == 8'd215)
					            state <= 3'd0;
					        else
					        	begin					    
									if(add_cnt == 6'd23)   
										begin
											rom_address <= rom_address;
											add_cnt <= 6'd0;
											state <= 3'd3;
											rd_en <= 1'b0;
										end
									else
										begin
											rom_address <= rom_address +8'd1;
											add_cnt <= add_cnt + 6'd1;
											state <= 3'd4;
										end
								end
						end
					else
						rom_address <= rom_address;
			  end
				endcase
			end
	end
	
//ROM for testing 	
// rom rom_inst(
			// .address(rom_address),
			// .clock(clkr),
			// .q(tx_data)
			// );
endmodule 