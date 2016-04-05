//********************************************************************************************
//module name:int_dsp_Linklayer_tx.v
//Author :IVAN
//Date :2010/3/3
//Description:generate an interrupt every 7.8125ms valid for low level,last time 
//this interrupt is sending interrupt from FPGA to DSP.
//*********************************************************************************************

module int_dsp_Linklayer_tx(

	input clk,                      //input clk is 200MHz
	input clkr,
	input rst,
	input tx_flag,                    //interrupt flag 
	input tx_begin,                                                                                                                                                   
	output reg int_tx,                 //generate an interrupt every 7.8125ms ,used for sending data
	output int_begin

);
//====================================================================================================
//=========================================generate int_tx interrupt===============================================
reg [15:0] cnt;
always@(posedge clk or posedge rst)
	begin
		if(rst)
			begin
				int_tx <= 1'b0;
				cnt <= 16'd200000;  //can't make FPGA generate interrupt at initial stage
			end
		else
			begin
				if(tx_begin)
					begin
						int_tx  <= 1'b1;
						cnt  <= 16'd0;
					end
				else     						//ͨ�����ƴ˼������ļ���ֵ���Եó��������ȵ�int�����ź�
					begin
						if(cnt < 16'd200000)
						    begin
								int_tx  <= 1'b1;
								cnt  <= cnt + 16'd1;
							end
						else
							begin
								int_tx  <= 1'b0;
							end
					end

			end
	end
//=====================================================================================================
//----------------------------------------------------------------------------------------
//                                      ����ͬ����
//----------------------------------------------------------------------------------------				
//������ͬ������ԭ�������źŵĿ�ʱ�������⣬��Ϊ��200M���ź�Ҫ�͵�20M��ʱ�����н���ʹ���ź�
//ԭʱ��������һ����ת��·
reg tx_begin_reg;
always@(posedge clk or posedge rst)
	begin
		if(rst)
			begin
			     tx_begin_reg <= 1'b1;
			end
		else
			begin
				if(tx_begin)
					tx_begin_reg <= ~tx_begin_reg;	
				else
					tx_begin_reg <= tx_begin_reg;
			end
	end

//��ʱ������ͬ����
reg q1,q2;//ͬ�������������
reg q3;   //��ͬ��������������һ���Ĵ���	
always@(posedge clkr or posedge rst)
	begin
		if(rst)
			begin
				q1 <= 1'b0;
				q2 <= 1'b0;
				q3 <= 1'b0;
			end
		else
			begin
				q1 <= tx_begin_reg;
				q2 <= q1 ;
				q3 <= q2;
			end
	
	end
assign 	int_begin = q3 ^ q2;
	

endmodule 
