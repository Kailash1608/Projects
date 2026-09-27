module bridge_top(hclk, hresetn, hwrite, hreadyin, haddr, hwdata, htrans, prdata, pwrite,
penable, pselx, paddr, pwdata, hreadyout, hresp, hrdata);

input hwrite, hclk, hresetn, hreadyin;
input [1:0] htrans;
input [31:0] haddr, hwdata, prdata;
output pwrite, penable, hreadyout;
output [2:0] pselx;
output [31:0] paddr, pwdata, hrdata;
output [1:0] hresp;

wire hwritereg, valid, hwritereg1;
wire [31:0] hwdata1, hwdata2, haddr1, haddr2;
wire [2:0] tempselx;

ahb_slave_interface I1(hclk, hresetn, hwrite, hreadyin, htrans, haddr, hwdata, prdata, hresp,
hrdata, valid, haddr1, haddr2, hwdata1, hwdata2, hwritereg, hwritereg1, tempselx);

apb_controller I2(hclk, hresetn, hwrite, hwritereg, valid, haddr, haddr1, haddr2, hwdata,
hwdata1, hwdata2, tempselx, penable, pwrite, hreadyout, paddr, pwdata, pselx);

endmodule