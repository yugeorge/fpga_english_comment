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
					input clkx,                  //MCASP��������ʱ��
					
					input rst,                   //�첽��λ�ź�
					
					output reg [31:0] rx_data_out,  //���յ�������  
					input [31:0] tx_data_in,     //����������
					
					input  dr,                   //MCASP�����ź�
					output reg dx,               //MCASP�����ź�

					output reg fsx,              //MCASP����֡ͬ���ź�
					output reg fsr,				 //MCASP����֡ͬ���ź�(DSP)
					
					output reg rx_ready,        //�������������źţ�ÿ32bit����һ��
					output reg tx_ready,			//�������������źţ�ÿ32bit����һ��
					
					input transform_en,         //���ݴ���ʹ���ź�
					
					input tx_data_en
);

//----------------------------------------------------------
//                    �������ݲ���
//----------------------------------------------------------

//��������״̬
parameter rx_idle   = 2'b00;
parameter rx_data   = 2'b01;
parameter rx_end    = 2'b10;

reg [7:0] rx_cnt;   //���ݱ��ؼ�����
reg [1:0] rx_state; //����״̬
reg [33:0] rx_data_reg;//���ݽ��ռĴ�����34bit������
reg dx1;


//����ת��״̬��
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

//�������ݲ���


always @(posedge clkx or posedge rst)
begin
    if(rst)
        begin 
        rx_data_reg <= 34'd0; //ʹ��34bit�ļĴ�������������Ч�����ǵ�32bit����һ����DSP�ſ�ʼ��������
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
//                    �������ݲ���
//----------------------------------------------------------

//��������״̬
parameter tx_idle   = 2'b00;
parameter tx_data   = 2'b01;
parameter tx_end    = 2'b11;
parameter tx_delay  = 2'b10;

reg [7:0] tx_cnt;   //�������ݱ��ؼ�����
reg [1:0] tx_state; //����״̬
reg [31:0] tx_data_reg;//�������ݴ洢�Ĵ���

//����ת��״̬��
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
						tx_ready <= 1'b1; //��������32bit���ݣ���߱�־λ
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
	

//�������ݲ���
always@(negedge clkr or posedge rst)
	begin
		if(rst)
			begin
				tx_data_reg <=32'd0;
				dx1 <= 0;
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
 





