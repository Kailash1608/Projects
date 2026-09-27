module ahb_to_apb_tb;

reg hclk, hresetn;
wire penable_o, pwrite_o;
wire [31:0] paddr_o, pwdata_o, prdata, paddr, pwdata;
wire [2:0] pselx_o, pselx;
wire [31:0] hrdata, haddr, hwdata;
wire hwrite, hreadyin, hreadyout;
wire [1:0] htrans;
wire penable, pwrite;
wire [1:0] hresp;

ahb_master ahb_m1(hclk, hresetn, hreadyout, hrdata, haddr, hwdata, hwrite, hreadyin, htrans);

bridge_top bt1(hclk, hresetn, hwrite, hreadyin, haddr, hwdata, htrans, prdata, pwrite, penable
, pselx, paddr, pwdata, hreadyout, hresp, hrdata);

apb_interface apb_i1(pwrite, penable, pselx, paddr, pwdata, pwrite_o, penable_o, pselx_o,
paddr_o, pwdata_o, prdata);

initial
hclk=1'b0;

always
#10 hclk= ~hclk;

task reset;
begin
    @(negedge hclk);
    hresetn=1'b0;
    @(negedge hclk);
    hresetn=1'b1;
end
endtask

initial
begin
    reset;
    ahb_m1.burst_write_wrap4();
end

initial
#1000 $finish;


endmodule