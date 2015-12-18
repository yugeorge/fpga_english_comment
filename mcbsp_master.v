//************************************************************************************************************
//Module: McBSP data sending module name:mcasp_master.v
//
//Created by:IVAN
//Created at:2010/12/10 
//
//
//Revised by: George Yu
//Revised At:2015/07/30
// 
// 
// 
//
//{/ o  o /}  
// ( (oo) )     P.S.:all the direction explaination is for DSP, so it's opposite for FPGA
//
//************************************************************************************************************

module mcasp_master(
					input clkr,
					input clkx,                  //McBSP receiving data clock
					
					input rst,                   //asynchronus reset signal
					
					output reg [31:0] rx_data_out,  //the receiving data
					input [31:0] tx_data_in,     // data to be send
					
					input  dr,                   //McBSP input signal
					output reg dx,               //McBSP output signal

					output reg fsx,              //McBSP send frame synchronisation 
					output reg fsr,				 //McBSP receive frame synchronisation (DSP)
					
					output reg rx_ready,        //Signal indicates receive data transfer complete, generate once every 32bit.
					output reg tx_ready,		//Signal indicated send data transfer complete, generate once every 32bit.
					
					input transform_en,         //Data transfer enable signal 
					
					input tx_data_en
);

//----------------------------------------------------------
//                    receive data part
//----------------------------------------------------------

//receive data status
parameter rx_idle   = 2'b00;
parameter rx_data   = 2'b01;
parameter rx_end    = 2'b10;

reg [7:0] rx_cnt;   //data bit counter
reg [1:0] rx_state; //receiving state
reg [33:0] rx_data_reg;//data receiving register //34bit data
reg dx1;


//the receiving state machine transfer
always@(negedge clkx or posedge rst)
	begin
		if(rst)
			begin
				rx_cnt<=8'd33;
				rx_state<=rx_idle;
				rx_ready <=1'b0;
				fsx <= 1'b0;
			end
		else
			begin
				case(rx_state)
				rx_idle:
						begin
							rx_ready <=1'b0;
							fsx <= 1'b0;
							if(transform_en)
								rx_state <= rx_data;
							else if(!transform_en)
								rx_state <= rx_idle;
							
						end
				rx_data:
						begin
							if(rx_cnt == 8'd33)
								fsx <= 1'b1;
							else
								fsx <= 1'b0;
							
							if(rx_cnt == 8'd0)
								begin
								rx_cnt <= 8'd33;
								rx_state <= rx_end;
								rx_ready <= 1'b1;
								end
							else
								begin
								rx_cnt <= rx_cnt - 8'd1;
								rx_state <= rx_data;
								end  
						end
				rx_end:
						begin
							rx_state <= rx_idle;
							rx_ready <= 1'b0;
							fsx <= 1'b0;
						end
				default:
						begin
							fsx <= 1'b0;
							rx_ready<=1'b0;
							rx_state <= rx_idle;
						end
				endcase
			end
	end

//the receiving data part


always @(posedge clkx or posedge rst)
begin
    if(rst)
        begin 
        rx_data_reg <= 34'd0; //to use 34bit register, the real effective data length is the low 32bit, after the first edge DSP starts to send data
        rx_data_out <= 32'd0;
        end
    else
        begin
        case(rx_state)
        rx_data:
            begin
			rx_data_reg[rx_cnt] <= dr;
            end
        rx_end:
            begin
			rx_data_out <= rx_data_reg[31:0];
            end
        default:
            begin
            rx_data_reg <= 33'd0;
			rx_data_out <= rx_data_out;
            end
        endcase
        end
end


//----------------------------------------------------------
//                    Part of sending data
//----------------------------------------------------------

//state of sending data
parameter tx_idle   = 2'b00;
parameter tx_data   = 2'b01;
parameter tx_end    = 2'b11;
parameter tx_delay  = 2'b10;

reg [7:0] tx_cnt;   //bit counter of sending data
reg [1:0] tx_state; //state of send
reg [31:0] tx_data_reg;//send data register

//state machine transfer of the send state
always@(posedge clkr or posedge rst)
	begin
		if(rst)
			begin
				tx_cnt <= 8'd31;
				tx_state <= tx_idle;
				tx_ready <= 1'b0;
			   fsr <= 1'b0;
				
			end
		
		else
			begin
			case(tx_state)
			tx_idle:    
				begin
					if(tx_data_en)
						tx_state <= tx_data;
					else
						tx_state <= tx_idle;
					tx_ready <= 1'b0;
					fsr <= 1'b0;
					
				end
			tx_data:
				begin
					if(tx_cnt == 8'd31)
						fsr <= 1'b1;
					else
						fsr <= 1'b0;
					
					if(tx_cnt == 8'd0)
						begin
						tx_cnt <= 8'd31;
						tx_state <= tx_end;
						tx_ready <= 1'b1; //when 32bit data completed sending , push tx_ready to high.
						end
					else
					   begin
                  
							
							tx_cnt <= tx_cnt - 8'd1;
						   tx_state <= tx_data;
							
						end              
				end
			tx_end:
				begin
					tx_state <= tx_delay;
					tx_ready <= 1'b0;
				end
			tx_delay:
				begin
					tx_state <= tx_idle;
					tx_ready <= 1'b0;
				end
			default:
				begin
					tx_state <= tx_idle;
				end
        endcase
			end
	end
	

//Sending data part
always@(negedge clkr or posedge rst)
	begin
		if(rst)
			begin
				tx_data_reg <=32'd0;
				dx1 <= 0;   //used for delay one clock cycle to meet the McBSP timing diagram
				dx <= 0;
			end
		else
			begin	
				case(tx_state)
			tx_idle:    
					begin
						tx_data_reg <= tx_data_in;						
					end
			tx_data:
					begin						
						dx1 <= tx_data_reg[tx_cnt];
						
					end
				endcase
				   dx<=dx1;
			end
	end

endmodule
 





