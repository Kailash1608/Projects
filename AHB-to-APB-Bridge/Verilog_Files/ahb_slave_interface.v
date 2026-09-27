module ahb_slave_interface(hclk_i, hresetn_i, hwrite_i, hreadyin_i, htrans_i,haddr_i, hwdata_i,
prdata_i, hresp_o, hrdata_o, valid_o, haddr1_o, haddr2_o, hwdata1_o, hwdata2_o, hwritereg_o,
 hwritereg1_o,tempselx_o);

input hclk_i, hresetn_i, hwrite_i, hreadyin_i;
input [1:0] htrans_i;
input [31:0] haddr_i, hwdata_i;
output [1:0] hresp_o;
output reg valid_o, hwritereg_o, hwritereg1_o;
output reg [31:0] haddr1_o, haddr2_o, hwdata1_o, hwdata2_o;
output reg [2:0] tempselx_o;
input  [31:0] prdata_i;
output reg [31:0] hrdata_o;

assign hresp_o=2'b00;

always@(posedge hclk_i)
    begin
    if(!hresetn_i)
        begin
        haddr1_o<=0;
        haddr2_o<=0;
        end
    
    else 
        begin
        haddr1_o<=haddr_i;
        haddr2_o<=haddr1_o;
        end
    end

always@(posedge hclk_i)
    begin
    if(!hresetn_i)
        begin
        hwdata1_o<=0;
        hwdata2_o<=0;
        end

    else
        begin
        hwdata1_o<=hwdata_i;
        hwdata2_o<=hwdata1_o;
        end
    end

always@(posedge hclk_i)
    begin
    if(!hresetn_i)
        begin
        hwritereg_o<=0;
        hwritereg1_o<=0;
        end
    
    else
        begin
        hwritereg_o<=hwrite_i;
        hwritereg1_o<=hwritereg_o;
        end
    end

always @(posedge hclk_i)
begin
    if(!hresetn_i)
        hrdata_o <= 32'b0;
    else
        hrdata_o <= prdata_i;
end


always@(*)
    begin
    valid_o=0;
    if((hreadyin_i==1)&&(haddr_i>=32'h8000_0000&&haddr_i<32'h8c00_0000)&&((htrans_i==2'b10)
    ||(htrans_i==2'b11)))
        begin
        valid_o=1;
        end
    
    else
        begin
        valid_o=0;
        end
    end

always@(*)
    begin
    tempselx_o=3'b000;
    if(haddr_i>=32'h8000_0000 && haddr_i<32'h8400_0000)
        begin
        tempselx_o=3'b001;
        end
    else if(haddr_i>=32'h8400_0000 && haddr_i<32'h8800_0000)
        begin
        tempselx_o=3'b010;
        end
    else if(haddr_i>=32'h8800_0000 && haddr_i<32'h8c00_0000)
        begin
        tempselx_o=3'b100;
        end
    else
        begin
        tempselx_o=3'b000;
        end
    end



endmodule