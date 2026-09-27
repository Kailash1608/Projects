module apb_controller(hclk_i, hresetn_i, hwrite_i, hwritereg_i, valid_o, haddr_i, haddr1_i,
haddr2_i, hwdata_i, hwdata1_i, hwdata2_i, tempselx_i, penable_o, pwrite_o,
hreadyout_o, paddr_o, pwdata_o, pselx_o);

input hclk_i, hresetn_i, hwrite_i, hwritereg_i, valid_o;
input [31:0] haddr_i, haddr1_i, haddr2_i, hwdata_i, hwdata1_i, hwdata2_i;
input [2:0] tempselx_i;
output reg penable_o, pwrite_o, hreadyout_o;
output reg [31:0] paddr_o, pwdata_o;
output reg [2:0] pselx_o;
reg pwrite_temp, penable_temp, hreadyout_temp;
reg [2:0] pselx_temp;
reg [31:0] paddr_temp, pwdata_temp;

parameter ST_IDLE=3'b000,
          ST_WWAIT=3'b001,
          ST_WRITE=3'b010,
          ST_WRITEP=3'b011,
          ST_WENABLEP=3'b100,
          ST_WENABLE=3'b101,
          ST_READ=3'b110,
          ST_RENABLE=3'b111;
          
          
reg [2:0] state, nxt_state;

always@(posedge hclk_i)
    begin
    if(!hresetn_i)
        begin
        state<=ST_IDLE;
        end
    
    else
        begin
        state<=nxt_state;
        end
    end
    
always@(*)
    begin
    case(state)
    ST_IDLE: begin
        if(valid_o && hwrite_i)
            begin
            nxt_state=ST_WWAIT;
            end
        else if(valid_o && ~hwrite_i)
            begin
            nxt_state=ST_READ;
            end
        else
            begin
            nxt_state=ST_IDLE;
            end
    end
    
    ST_WWAIT: begin
        if(valid_o)
            begin
            nxt_state=ST_WRITEP;
            end
        else 
            begin
            nxt_state=ST_WRITE;
            end
        end
    
    ST_WRITEP: begin
    nxt_state=ST_WENABLEP;
    end
    
    ST_WRITE: begin
        if(valid_o)
            begin
            nxt_state=ST_WENABLEP;
            end
        else
            begin
            nxt_state=ST_WENABLE;
            end
        end
        
    ST_WENABLEP: begin
        if(valid_o && hwritereg_i)
            begin
            nxt_state=ST_WRITEP;
            end
        else if(~valid_o && hwritereg_i)
            begin
            nxt_state=ST_WRITE;
            end
        else if(~hwritereg_i)
            begin
            nxt_state=ST_READ;
            end
        else
            begin
            nxt_state=ST_WENABLEP;
            end
        end
    
    ST_WENABLE: begin
        if(valid_o && hwrite_i)
            begin
            nxt_state=ST_WWAIT;
            end
        else if(valid_o && ~hwrite_i)
            begin
            nxt_state=ST_READ;
            end
        else if(~valid_o)
            begin
            nxt_state=ST_IDLE;
            end
        else
            begin
            nxt_state=ST_WENABLE;
            end        
        end
    
    ST_READ: begin
    nxt_state=ST_RENABLE;
    end
    
    ST_RENABLE: begin
        if(valid_o && hwrite_i)
            begin
            nxt_state=ST_WWAIT;
            end
        else if(valid_o && ~hwrite_i)
            begin
            nxt_state=ST_READ;
            end
        else if(~valid_o)
            begin
            nxt_state=ST_IDLE;
            end
        else 
            begin
            nxt_state=ST_RENABLE;
            end        
        end
    
    default: nxt_state=ST_IDLE;          
    endcase
    end
    
always@(*)begin
    case(state)
    ST_IDLE: begin
        if(valid_o && hwrite_i)begin  
        hreadyout_temp=1'b1;
        pselx_temp=3'b0;
        penable_temp=1'b0;
        end
        else if(valid_o && ~hwrite_i) begin
        hreadyout_temp=1'b0;
        paddr_temp=haddr_i;
        pwrite_temp=1'b0;
        pselx_temp=tempselx_i;
        penable_temp=1'b0;
        end
        end
    
    ST_WWAIT: begin
    hreadyout_temp=1'b0;
    paddr_temp=haddr1_i;
    pwrite_temp=1'b1;
    pselx_temp=tempselx_i;
    pwdata_temp=hwdata_i;
    end

    ST_WRITE: begin
    hreadyout_temp=1'b1;
    penable_temp=1'b1;
    end
    
    ST_WRITEP: begin
    hreadyout_temp=1'b1;
    penable_temp=1'b1;
    end
    
    ST_WENABLEP: begin
    hreadyout_temp=1'b0;
    paddr_temp=haddr2_i;
    penable_temp=1'b0; 
    pwdata_temp=hwdata_i;
    end
    
    ST_WENABLE: begin
    hreadyout_temp=1'b0;
    paddr_temp=haddr2_i;
    penable_temp=1'b0;
    pwdata_temp=hwdata_i;
    end
    
    ST_READ: begin
    hreadyout_temp=1'b1;
    penable_temp=1'b1;
    end
    
    ST_RENABLE: begin
    paddr_temp=haddr_i;
    hreadyout_temp=1'b0;
    penable_temp=1'b0;
    end
    
    endcase
end

always@(posedge hclk_i) begin
    if(!hresetn_i) begin
    penable_o<=0;
    pselx_o<=0;
    hreadyout_o<=1'b1;
    end
    
    else begin
    pwrite_o<=pwrite_temp;
    penable_o<=penable_temp;
    pselx_o<=pselx_temp;
    pwdata_o<=pwdata_temp;
    paddr_o<=paddr_temp;
    hreadyout_o<=hreadyout_temp;
    end
end

endmodule