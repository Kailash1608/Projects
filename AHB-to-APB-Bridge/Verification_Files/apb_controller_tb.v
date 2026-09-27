`timescale 1ns/1ps

module apb_controller_tb;

reg hclk_i;
reg hresetn_i;

reg hwrite_i;
reg valid_o;

reg [31:0] haddr_i;
reg [31:0] hwdata_i;
reg [2:0]  tempselx_i;

// Pipeline signals
reg hwritereg_i;
reg [31:0] haddr1_i;
reg [31:0] haddr2_i;
reg [31:0] hwdata1_i;
reg [31:0] hwdata2_i;

// DUT outputs
wire penable_o;
wire pwrite_o;
wire hreadyout_o;
wire [31:0] paddr_o;
wire [31:0] pwdata_o;
wire [2:0]  pselx_o;


//--------------------------------------------------
// DUT
//--------------------------------------------------

apb_controller DUT(
    hclk_i,
    hresetn_i,
    hwrite_i,
    hwritereg_i,
    valid_o,
    haddr_i,
    haddr1_i,
    haddr2_i,
    hwdata_i,
    hwdata1_i,
    hwdata2_i,
    tempselx_i,
    penable_o,
    pwrite_o,
    hreadyout_o,
    paddr_o,
    pwdata_o,
    pselx_o
);


//--------------------------------------------------
// Clock
//--------------------------------------------------

always #5 hclk_i = ~hclk_i;


//--------------------------------------------------
// Generate pipeline registers
//--------------------------------------------------

always @(posedge hclk_i)
begin
    if(!hresetn_i)
    begin
        haddr1_i    <= 0;
        haddr2_i    <= 0;

        hwdata1_i   <= 0;
        hwdata2_i   <= 0;

        hwritereg_i <= 0;
    end
    else
    begin
        haddr1_i    <= haddr_i;
        haddr2_i    <= haddr1_i;

        hwdata1_i   <= hwdata_i;
        hwdata2_i   <= hwdata1_i;

        hwritereg_i <= hwrite_i;
    end
end


//--------------------------------------------------
// Burst Write Stimulus
//--------------------------------------------------

task burst_write_custom;
begin

    // Cycle 2 : A1
    @(posedge hclk_i);
    #1;
    valid_o    = 1'b1;
    hwrite_i   = 1'b1;
    tempselx_i = 3'b001;

    haddr_i    = 32'h8000_0020;   // A1
    hwdata_i   = 32'hxxxxxxxx;    // X


    // Cycle 3 : A2 + D1
    @(posedge hclk_i);
    #1;
    haddr_i    = 32'h8000_0024;   // A2
    hwdata_i   = 32'h11111111;    // D1


    // Cycle 4 : A3 + D2
    @(posedge hclk_i);
    #1;
    haddr_i    = 32'h8000_0028;   // A3
    hwdata_i   = 32'h22222222;    // D2


    // Cycle 5 : A3 + D2
    @(posedge hclk_i);
    #1;
    haddr_i    = 32'h8000_0028;
    hwdata_i   = 32'h22222222;


    // Cycle 6 : A4 + D3
    @(posedge hclk_i);
    #1;
    haddr_i    = 32'h8000_002C;   // A4
    hwdata_i   = 32'h33333333;    // D3


    // Cycle 7 : A4 + D3
    @(posedge hclk_i);
    #1;
    haddr_i    = 32'h8000_002C;
    hwdata_i   = 32'h33333333;


    // Cycle 8 : X + D4
    @(posedge hclk_i);
    #1;
    haddr_i    = 32'hxxxxxxxx;
    hwdata_i   = 32'h44444444;
    hwrite_i   = 1'b0;
    valid_o    = 1'b0;


    // Cycle 9 : X + D4
    @(posedge hclk_i);
    #1;
    haddr_i    = 32'hxxxxxxxx;
    hwdata_i   = 32'h44444444;


    // Extra clock 1
    @(posedge hclk_i);

    // Extra clock 2
    @(posedge hclk_i);

    // Extra clock 3
    @(posedge hclk_i);

end
endtask


//--------------------------------------------------
// Main
//--------------------------------------------------

initial
begin

    hclk_i      = 0;
    hresetn_i   = 0;

    hwrite_i    = 1'bx;
    valid_o     = 1'b0;

    haddr_i     = 32'hxxxxxxxx;
    hwdata_i    = 32'hxxxxxxxx;

    tempselx_i  = 3'b000;

    #20;
    hresetn_i = 1;

    burst_write_custom();

    #50;
    $finish;

end


//--------------------------------------------------
// Monitor
//--------------------------------------------------

initial
begin
    $monitor(
    "T=%0t STATE=%0d HADDR=%h HWDATA=%h HREADYOUT=%b PADDR=%h PWDATA=%h PSEL=%b PENABLE=%b",
    $time,
    DUT.state,
    haddr_i,
    hwdata_i,
    hreadyout_o,
    paddr_o,
    pwdata_o,
    pselx_o,
    penable_o
    );
end

endmodule