module ahb_master(input hclk, hresetn, hr_readyout, input [31:0] hrdata, output reg [31:0]
haddr, hwdata, output reg hwrite, hready_in, output reg [1:0] htrans);

reg [2:0] hburst;
reg [2:0] hsize;
integer i;
task single_write;
    begin
    @(posedge hclk)
    #1;
    begin
    haddr=32'h8000_0000;
    hwrite=1;
    htrans=2'b10;
    hsize=3'b000;
    hburst=3'b000;
    hready_in=1;
    
    end
    
    @(posedge hclk)
    #1;
    begin
    haddr=32'h0000_0000;
    hwdata=32'h24;
    hwrite=0;
    htrans=2'b00;
    end
    end
endtask

task single_read;
    begin
    @(posedge hclk)
    #1;
    begin
    haddr=32'h8000_0000;
    hwrite=0;
    htrans=2'b10;
    hsize=3'b000;
    hburst=3'b000;
    hready_in=1;
    end
    
    @(posedge hclk)
    #1;
    begin
    htrans=2'b00;
    end
    end
endtask

task burst_write_wrap4;
    begin
    @(posedge hclk)
    #1;
    begin
    haddr=32'h8000_0020;
    hwrite=1;
    htrans=2'b10;
    hsize=3'b000;
    hburst=3'b010;
    hready_in=1;
    end
    
    @(posedge hclk)
    #1;
    begin
    haddr={haddr[31:2], haddr[1:0]+1'b1};
    hwdata={$random}%1024;
    htrans=2'b11;
    end
    
    for(i=0; i<2; i=i+1)
    begin
    @(posedge hclk)
    #1;
    begin
    haddr={haddr[31:2], haddr[1:0]+1'b1};
    hwdata={$random}%1024;
    htrans=2'b11;
    #1;
    @(posedge hclk);
    end
    end
    
    @(posedge hclk)
    #1;
    begin
    haddr=32'h0000_0000;
    hwdata={$random}%1024;
    hwrite=0;
    htrans=2'b00;
    end
    end
endtask

task burst_write_incr4;
    begin
    @(posedge hclk)
    #1;
    begin
    haddr=32'h8000_0020;
    hwrite=1;
    htrans=2'b10;
    hsize=3'b000;
    hburst=3'b011;
    hready_in=1;
    end
    
    @(posedge hclk)
    #1;
    begin
    haddr=haddr+1'b1;
    hwdata={$random}%256;
    htrans=2'b11;
    end
    
    for(i=0;i<2;i=i+1)
    begin
    @(posedge hclk)
    #1;
    begin
    haddr=haddr+1'b1;
    hwdata={$random}%256;
    htrans=2'b11;
    #1;
    @(posedge hclk);
    end
    end
    
    @(posedge hclk)
    #1;
    begin
    haddr=32'h0000_0000;
    hwdata={$random}%256;
    hwrite=0;
    htrans=2'b00;
    end
    end
endtask

task burst_read_wrap4;
begin
    @(posedge hclk)
    #1;
    begin
    haddr=32'h8000_0020;
    hwrite=0;
    htrans=2'b10;
    hsize=3'b000;
    hburst=3'b010;
    hready_in=1;
    end
    
    for(i=0; i<3; i=i+1)
    begin
    @(posedge hclk)
    #1;
    begin
    haddr={haddr[31:2], haddr[1:0]+1'b1};
    htrans=2'b11;
    #1;
    @(posedge hclk);
    end
    end
    
    @(posedge hclk)
    #1;
    begin
    hwrite=1;
    htrans=2'b00;
    end
    end
endtask
    
    
endmodule