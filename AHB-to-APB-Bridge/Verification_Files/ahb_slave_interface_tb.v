`timescale 1ns/1ps

module ahb_slave_interface_tb;

reg hclk_i;
reg hresetn_i;
reg hwrite_i;
reg hreadyin_i;
reg [1:0] htrans_i;
reg [31:0] haddr_i;
reg [31:0] hwdata_i;

wire [1:0] hresp_o;
wire valid_o;
wire hwritereg_o;
wire [31:0] haddr1_o;
wire [31:0] haddr2_o;
wire [31:0] hwdata1_o;
wire [31:0] hwdata2_o;
wire [2:0] tempselx_o;

ahb_slave_interface DUT(
    .hclk_i(hclk_i),
    .hresetn_i(hresetn_i),
    .hwrite_i(hwrite_i),
    .hreadyin_i(hreadyin_i),
    .htrans_i(htrans_i),
    .haddr_i(haddr_i),
    .hwdata_i(hwdata_i),
    .hresp_o(hresp_o),
    .valid_o(valid_o),
    .haddr1_o(haddr1_o),
    .haddr2_o(haddr2_o),
    .hwdata1_o(hwdata1_o),
    .hwdata2_o(hwdata2_o),
    .hwritereg_o(hwritereg_o),
    .tempselx_o(tempselx_o)
);


always #5 hclk_i = ~hclk_i;


task ahb_transfer;
input [31:0] addr;
input [31:0] data;
input write;
input ready;
input [1:0] trans;

begin
    @(posedge hclk_i);
    #1;

    haddr_i    = addr;
    hwdata_i   = data;
    hwrite_i   = write;
    hreadyin_i = ready;
    htrans_i   = trans;
end
endtask


initial
begin

    hclk_i     = 0;
    hresetn_i  = 0;
    hwrite_i   = 0;
    hreadyin_i = 0;
    htrans_i   = 2'b00;
    haddr_i    = 0;
    hwdata_i   = 0;


    #20;
    hresetn_i = 1;

    //--------------------------------------------------
    // SLAVE 1 ADDRESS RANGE
    // tempselx = 001
    // valid = 1
    //--------------------------------------------------

    ahb_transfer(
        32'h8000_0010,
        32'hAAAA1111,
        1'b1,
        1'b1,
        2'b10
    );

    //--------------------------------------------------
    // SLAVE 2 ADDRESS RANGE
    // tempselx = 010
    //--------------------------------------------------

    ahb_transfer(
        32'h8500_0010,
        32'hBBBB2222,
        1'b1,
        1'b1,
        2'b10
    );

    //--------------------------------------------------
    // SLAVE 3 ADDRESS RANGE
    // tempselx = 100
    //--------------------------------------------------

    ahb_transfer(
        32'h8900_0010,
        32'hCCCC3333,
        1'b1,
        1'b1,
        2'b10
    );

    //--------------------------------------------------
    // IDLE TRANSFER
    // valid = 0
    //--------------------------------------------------

    ahb_transfer(
        32'h8000_0010,
        32'hDDDD4444,
        1'b1,
        1'b1,
        2'b00
    );

    //--------------------------------------------------
    // BUSY/SEQ TRANSFER
    // valid = 1
    //--------------------------------------------------

    ahb_transfer(
        32'h8000_0020,
        32'hEEEE5555,
        1'b1,
        1'b1,
        2'b11
    );

    //--------------------------------------------------
    // hreadyin = 0
    // valid = 0
    //--------------------------------------------------

    ahb_transfer(
        32'h8000_0030,
        32'hFFFF6666,
        1'b1,
        1'b0,
        2'b10
    );

    //--------------------------------------------------
    // INVALID ADDRESS
    // valid = 0
    //--------------------------------------------------

    ahb_transfer(
        32'h9000_0000,
        32'h12345678,
        1'b1,
        1'b1,
        2'b10
    );

    //--------------------------------------------------
    // READ TRANSFER
    //--------------------------------------------------

    ahb_transfer(
        32'h8000_0040,
        32'h00000000,
        1'b0,
        1'b1,
        2'b10
    );

    //--------------------------------------------------
    // Additional transfers to verify pipelines
    //--------------------------------------------------

    ahb_transfer(
        32'h8000_0050,
        32'h11111111,
        1'b1,
        1'b1,
        2'b10
    );

    ahb_transfer(
        32'h8000_0060,
        32'h22222222,
        1'b1,
        1'b1,
        2'b10
    );

    ahb_transfer(
        32'h8000_0070,
        32'h33333333,
        1'b1,
        1'b1,
        2'b10
    );

    #50;

    $finish;

end


initial
begin
$monitor(
"TIME=%0t ADDR=%h DATA=%h VALID=%b TEMPSEL=%b HADDR1=%h HADDR2=%h HWDATA1=%h HWDATA2=%h HWRITE_REG=%b",
$time,
haddr_i,
hwdata_i,
valid_o,
tempselx_o,
haddr1_o,
haddr2_o,
hwdata1_o,
hwdata2_o,
hwritereg_o
);
end

endmodule