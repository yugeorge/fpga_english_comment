//************************************************************************************************************
//module：McBsp data receive main module filename:mcasp_slaver.v
//Functional Descriptiion:  to complete transmission between FPGA and DSP, standard McBsp module 
//
//
//Original Author:IVAN
//Created At :2010/12/12 


//Revised By: George Yu
// Revised at 2015/07/30

//
// 
//{/ o  o /}  
// ( (oo) )     in this file, all the r,x and for DSP,so the direction is opposite to FPGA
// 
//************************************************************************************************************
module mcasp_slaver(
					input clk,                //SYS clk 200M 
					input rst,
					
					input dr,                 //MCBSP receive signal
					input fsx,
					input clkx,
					
					input transform_en,		  //Data sending enable signal, only when this signal enables can DSP send date to FPGA.
					
					output reg rx_ready,
					output reg [31:0] rx_data_out,//the received data
					output reg [11:0] data_cnt,
					output reg read_fh_num_en,    //signals reading the hopping number
					
					output fsx_risingedge
);

//detect the fsr signal
reg[2:0] fsx_r;//3bit register which is used for detect fsx signal  
always@(posedge clk or posedge rst)
	begin
		if(rst)
			begin
				fsx_r <= 3'b000;			
			end
		else
			begin
				fsx_r <={fsx_r[1:0],fsx}; //shift register
			end
	end
	
//assign  fsx_risingedge  =  (fsx_r==3'b011);  	// this line is used for transforming McASP to McBSP   
assign  fsx_risingedge  =  (fsx_r==3'b110); 

//detect the clkx signal
reg[5:0] clkx_r;//5bit shift register,used for detect clkx signal. The reason why we use 5bit register is to give this signal  some time delays compared with fsr so the data acquisition can be right 
always@(posedge clk or posedge rst)
	begin
		if(rst)
			begin
				clkx_r <= 6'd0;			
			end
		else
			begin
				clkx_r <={clkx_r[4:0],clkx}; //shift register
			end
	end
	
(*keep*) wire clkx_risingedge  =  (clkx_r[5:4]==2'b01);  	  // use this clkx to detect the rising edge
wire clkx_fallingedge =  (clkx_r[5:4]==2'b10);     // use this clkx to detect the falling edge




//McBSP receive data status
parameter rx_idle = 3'b001;
parameter rx_data = 3'b010;
parameter rx_end  = 3'b100;

reg[2:0] rx_state;
reg[7:0] rx_cnt;      //receive data count 
//reg[7:0] data_cnt;    //send data count

//rhe state machine that controls data receiving
always@(posedge clk or posedge rst)
	begin
		if(rst)
			begin
				rx_state <= rx_idle;
				rx_cnt <= 8'd31;
				rx_ready <= 1'b0;
				data_cnt <= 12'd0;
				read_fh_num_en <= 1'b0;
			end
		else
			begin
				case(rx_state)
		rx_idle:
				begin
					if(transform_en)
						begin
							read_fh_num_en <= 1'b0;
							if(fsx_risingedge)
								rx_state <= rx_data;
							else
								rx_state <= rx_idle;
						end
					else
						begin
							rx_state <= rx_idle;
							read_fh_num_en <= 1'b1;
						end
				end
		rx_data:
				begin
				if(transform_en)
					if(clkx_risingedge)  //capture data at the rising edge of clkx
						begin
							if(rx_cnt == 8'd0)
								begin
									if(data_cnt == 12'd720)//
										begin
											read_fh_num_en <= 1'b1; //when DSP transfered data to DSP completed, pull the read enable signal to high,
											rx_state <= rx_end;		//to extend the time the reading enable signal at high
											data_cnt <= 12'd0;
										end
									else
										begin
											rx_state <= rx_data;									
											data_cnt <= data_cnt + 12'd1;
										end
										
									rx_ready <= 1'b1;
									rx_cnt <= 8'd31;
										
								end
							else
								begin
									rx_cnt <= rx_cnt - 8'd1;
									rx_state <= rx_data;
									rx_ready <= 1'b0;
								end
						end
				if(!transform_en)
					begin
						rx_state <= rx_idle;
					end
			end	

		rx_end:
				begin
					read_fh_num_en <= 1'b1;
					rx_state <= rx_idle;
					rx_ready <= 1'b0;
				end
		default:
				begin
				    read_fh_num_en <= 1'b0;
					rx_state <= rx_idle;
					rx_ready <= 1'b0;
				end
				endcase			
			end	
	end

//Part of receiving data

reg[31:0] rx_data_reg;//Data Buffer
always @(posedge clk or posedge rst)
begin
    if(rst)
        begin 
        rx_data_reg <= 32'd0; 
        rx_data_out <= 32'd0;
        end
    else
        begin
        case(rx_state)
        rx_data:
            begin
			
			if(clkx_risingedge)
				begin
				rx_data_reg[rx_cnt] <= dr;
					if(rx_cnt == 8'd31)
						rx_data_out	<= rx_data_reg;
					else
						rx_data_out <= rx_data_out;
					end
				end
        // rx_end:
            // begin
			// rx_data_out <= rx_data_reg;
            // end
        default:
            begin
            rx_data_reg <= 32'd0;
			rx_data_out <= rx_data_out;
            end
        endcase
        end
end

endmodule 