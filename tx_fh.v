module tx_fh(

input  clk,
input  rst,

input  [31:0] fh_num,           //the hopping number register

input  [20:0] tod_h,
input  [10:0]  tod_l,

output [9:0]  freq_ram_addr,    // output address for frequency
input  [31:0] freq_ram_data,    // input for frequency control words
 
output reg [31:0] freq_factor,  // output for frequency contorl words
output reg freq_en              // valid signal for frequency control words

);
  
  
assign freq_ram_addr = tod_h[9:0];
  
//assign freq_ram_addr = (tod_h < fh_num[20:0]) ? tod_h[9:0] : 10'd0;      // generate address for frequency table��tod_h is the count for hooping frequency

//assign freq_ram_addr = (tod_h[9:0] < 10'd32) ? 10'd0 : ((tod_h[9:0] < 10'd40 && tod_h[9:0] >= 10'd32) ? 10'd32 : 10'd40);
//assign freq_ram_addr = (tod_h[9:0] < 10'd100) ? 10'd0 : ((tod_h[9:0] < 10'd250 && tod_h[9:0] >= 10'd100) ? 10'd32 : 10'd40);
//����ϵͳ��ͬʱ���ݿ���ϵͳ����ƣ�������ͬ����ʱ�����Ƶ�ʱ�ĵ�һ��Ƶ�㣬��ͬ������32�����õ�33��Ƶ�㣬���ݲ�����������40��Ƶ��(data part we take the fourth)
//������Ƶ�Ŀ����Ϊ�˼��ݿ���
//assign freq_ram_addr =  10'd0;
always @(posedge clk or posedge rst)
begin
    if(rst)
        begin
        freq_factor <= 32'd0;
        freq_en <= 1'b0; 		
        end
    else
        begin                                                   //��ʹ��AD9957��Ϊ������ʹ�õ�ʱ��Ҫ��AD9957������ƵƵ�ʣ�Ҫ���Ǽ���ʱ�����ڵĶ�ȡƵ�ʱ��ʱ��														
         if((tod_h < fh_num[20:0]) && (tod_l == 11'd12))        //������һ����Ҫע�⣬���ص�ʹ���ź�Ҫ����100ns����Ϊ�����spi���ڴ�������     
            begin											    //��ʱ��Ϊ10M
            freq_factor <= freq_ram_data;						//������Ƶ����ʱ������Ϊ10��12.5ns
            freq_en <= 1'b0;//frequency control words load enable, we must ensure this signal is valid for 100ns,that is 10MHz
            end
		
		 else if((tod_h < fh_num[20:0]) && (tod_l == 11'd16))          
            begin											   
            freq_factor <= freq_factor;
            freq_en <= 1'b1;
            end
			
		 else if((tod_h < fh_num[20:0]) && (tod_l == 11'd28))          
            begin											   
            freq_factor <= freq_factor;
            freq_en <= 1'b0;
            end	
			
//�����ʹ����޶���������ʱ����ȫ0Ƶ�㣬����Ƶ��Ϊ0          
		 // else if((tod_h == fh_num[20:0]) && (tod_l == 11'd13))							         
            // begin											   
				// freq_factor <= 32'd0;
				// freq_en <= 1'b1;
            // end
		 // else if((tod_h == fh_num[20:0]) && (tod_l == 11'd22))							        
            // begin											   
				// freq_factor <= 32'd0;
				// freq_en <= 1'b0;
            // end
		 else
            begin
            freq_factor <= freq_factor;
            freq_en <= freq_en;
            end
        end
end


endmodule
