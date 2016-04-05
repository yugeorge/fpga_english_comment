//********************************************************************************************
//ģ�����ƣ�int_dsp_Linklayer_tx.v
//���ߣ�IVAN
//ʱ��:2010/3/3
//������ÿ��7.8125ms����һ���жϣ��͵�ƽ��Ч���͵�ƽ����ʱ������60us���ݶ�ÿ��ʱ϶����һ���жϣ�
//���ж���FPGA��DSP�ķ����ж�
//�q�������r 
//{/ o  o /}  
// ( (oo) )     ���жϲ��������Ǻ����Ӣ���·��DSP����ͨ�ŵ�ģ��
// �� ����
//*********************************************************************************************

module int_dsp_Linklayer_tx(

	input clk,                      //������ϵͳʱ��Ϊ160MHZ
	input clkr,
	input rst,
	input tx_flag,                    //�жϱ�־λ
	input tx_begin,                                                                                                                                                   
	output reg int_tx,                 //ÿ7.8125����һ���жϣ������������
	output int_begin

);
//====================================================================================================
//=========================================����int_tx�ж�===============================================
reg [15:0] cnt;
always@(posedge clk or posedge rst)
	begin
		if(rst)
			begin
				int_tx <= 1'b0;
				cnt <= 16'd200000;  //��ʼʱ�̲�����FPGA�����ж�
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