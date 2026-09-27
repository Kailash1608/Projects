module apb_interface(input pwrite, penable, input [2:0] pselx, input [31:0] paddr, pwdata, output 
pwrite_out, penable_out, output [2:0] pselx_out, output [31:0] paddr_out, pwdata_out,
output reg [31:0] pr_data);

assign pwrite_out = pwrite;
assign penable_out = penable;
assign pselx_out = pselx;
assign paddr_out = paddr;
assign pwdata_out = pwdata;

always@(*) begin
if(!pwrite && penable)
pr_data = {$random};
else
pr_data = 32'h0;
end


endmodule