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
  
//assign freq_ram_addr = (tod_h < fh_num[20:0]) ? tod_h[9:0] : 10'd0;      // generate address for frequency table，tod_h is the count for hooping frequency

//assign freq_ram_addr = (tod_h[9:0] < 10'd32) ? 10'd0 : ((tod_h[9:0] < 10'd40 && tod_h[9:0] >= 10'd32) ? 10'd32 : 10'd40);
//assign freq_ram_addr = (tod_h[9:0] < 10'd100) ? 10'd0 : ((tod_h[9:0] < 10'd250 && tod_h[9:0] >= 10'd100) ? 10'd32 : 10'd40);
//慢跳系统（同时兼容快跳系统的设计），当粗同步的时候采用频率表的第一个频点，精同步即第32跳采用第33个频点，数据部分整个采用40号频点(data part we take the fourth)
//这样设计的目的是为了兼容快跳
//assign freq_ram_addr =  10'd0;
always @(posedge clk or posedge rst)
begin
    if(rst)
        begin
        freq_factor <= 32'd0;
        freq_en <= 1'b0; 		
        end
    else
        begin                                                   //当使用AD9957作为调制器使用的时候，要给AD9957加载跳频频率，要考虑几个时钟周期的读取频率表的时间														
         if((tod_h < fh_num[20:0]) && (tod_l == 11'd12))        //并且有一点需要注意，加载的使能信号要超过100ns，因为后面的spi串口传送数据     
            begin											    //的时钟为10M
            freq_factor <= freq_ram_data;						//调整跳频保护时间增加为10个12.5ns
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
			
//当发送大于限定的跳数的时候发送全0频点，将载频变为0          
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
