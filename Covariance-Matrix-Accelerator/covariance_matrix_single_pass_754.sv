module covariance_matrix_single_pass_float_OPT #(
    parameter DATA_WIDTH = 16,      // Change to 12 or 10 if your sensor is smaller!
    parameter DIMENSIONS = 3,
    parameter SAMPLES    = 4
)(
    input  logic clk,
    input  logic rst,
    input  logic start,
    input  logic signed [DATA_WIDTH-1:0] data_in,
    input  logic data_valid, 

    output logic done,
    output logic [31:0] result_out,      
    output logic [4:0]  result_index,    
    output logic        result_valid     
);

    // --- 1. Parameter Calculations ---
    // XXT needs to hold sum of (Sample^2). Max value approx SAMPLES * (2^(DATA_WIDTH*2))
    localparam XXT_ACCUM_WIDTH = 2*DATA_WIDTH + $clog2(SAMPLES); 
    // SUM needs to hold sum of Samples. Max value approx SAMPLES * (2^DATA_WIDTH)
    localparam SUM_ACCUM_WIDTH = DATA_WIDTH + $clog2(SAMPLES);
    
    localparam TOTAL_RESULTS = DIMENSIONS * DIMENSIONS + DIMENSIONS; // 12
    localparam RESULT_INDEX_WIDTH = $clog2(TOTAL_RESULTS);
    
    // --- 2. Internal Registers ---
    // We keep the accumulators (Memory) - these cannot be reduced
    logic signed [XXT_ACCUM_WIDTH-1:0] XX_T_sum [DIMENSIONS-1:0][DIMENSIONS-1:0];
    logic signed [SUM_ACCUM_WIDTH-1:0] dim_sum  [DIMENSIONS-1:0];
    logic signed [DATA_WIDTH-1:0]      current_sample_reg [DIMENSIONS-1:0];

    // Counters
    logic [$clog2(DIMENSIONS)-1:0] dim_count;
    logic [$clog2(SAMPLES)-1:0]    sample_count;
    logic [RESULT_INDEX_WIDTH:0]   result_count; // Extra bit to detect "done" cleanly

    integer i, j;
    
    // FSM
    typedef enum {IDLE, PROCESS_DATA, PROCESS_RESULTS, DONE_STATE} state_t;
    state_t state, next_state;

    // --- 3. FSM Logic ---
    always_ff @(posedge clk or posedge rst) begin
        if (rst) state <= IDLE;
        else     state <= next_state;
    end

    always_comb begin
        next_state = state;
        done = 1'b0;
        result_valid = 1'b0; 

        case (state)
            IDLE: if (start) next_state = PROCESS_DATA;
            
            PROCESS_DATA: begin
                if (data_valid && sample_count == SAMPLES-1 && dim_count == DIMENSIONS-1)
                    next_state = PROCESS_RESULTS;
            end
            
            PROCESS_RESULTS: begin
                result_valid = 1'b1;
                if (result_count == TOTAL_RESULTS - 1)
                    next_state = DONE_STATE;
            end
            
            DONE_STATE: begin
                done = 1'b1;
                if (!start) next_state = IDLE;
            end
        endcase
    end

    // --- 4. Datapath (Accumulation) ---
    always_ff @(posedge clk) begin
        if (rst) begin
            dim_count <= '0;
            sample_count <= '0;
            result_count <= '0;
            for (i=0; i<DIMENSIONS; i++) begin
                dim_sum[i] <= '0; 
                for (j=0; j<DIMENSIONS; j++) XX_T_sum[i][j] <= '0;
            end
        end else begin
            case (state)
                IDLE: begin
                   result_count <= '0;
                   if (start) begin
                       // Optional: Clear sums here if you want auto-clear on start
                       dim_count <= '0;
                       sample_count <= '0;
                   end
                end

                PROCESS_DATA: begin
                    if (data_valid) begin
                        current_sample_reg[dim_count] <= data_in;

                        if (dim_count == DIMENSIONS - 1) begin
                            // Calculate all updates at end of sample row
                            for (i = 0; i < DIMENSIONS; i++) begin
                                // Update XX_T
                                for (j = 0; j < DIMENSIONS; j++) begin
                                    XX_T_sum[i][j] <= XX_T_sum[i][j] + 
                                        (((i==DIMENSIONS-1) ? data_in : current_sample_reg[i]) * ((j==DIMENSIONS-1) ? data_in : current_sample_reg[j]));
                                end
                                // Update Sum
                                dim_sum[i] <= dim_sum[i] + ((i==DIMENSIONS-1) ? data_in : current_sample_reg[i]);
                            end
                            sample_count <= sample_count + 1;
                            dim_count <= '0;
                        end else begin
                            dim_count <= dim_count + 1;
                        end
                    end
                end

                PROCESS_RESULTS: begin
                    result_count <= result_count + 1;
                end
            endcase
        end
    end

    // --- 5. OPTIMIZATION: Resource Shared Output Logic ---
    
    // A. Multiplex the Integer Value
    // We select WHICH integer we want to convert based on result_count.
    // We sign-extend everything to the largest width (XXT_ACCUM_WIDTH) so they fit in one wire.
    logic signed [XXT_ACCUM_WIDTH-1:0] current_int_to_convert;
    
    always_comb begin
        if (result_count < DIMENSIONS*DIMENSIONS) begin
            // We are outputting the Matrix (3x3=9 values)
            // Math: Row = count / DIM, Col = count % DIM
            // Since DIM=3 is not power of 2, division is expensive.
            // But since result_count increments linearly, we can just look it up.
            // For a general implementation, we map linearly:
            current_int_to_convert = XX_T_sum[result_count / DIMENSIONS][result_count % DIMENSIONS];
        end else begin
            // We are outputting the Sums (3 values)
            // Index 9, 10, 11 -> maps to dim_sum[0, 1, 2]
            current_int_to_convert = dim_sum[result_count - (DIMENSIONS*DIMENSIONS)]; 
        end
    end

    // B. Single Shared Converter
    // Only ONE instance of this logic is created!
    assign result_out = f_signed_to_float_SHARED(current_int_to_convert);
    assign result_index = result_count;


    // --- 6. Shared Conversion Function ---
    // Handles the maximum width input. Smaller inputs are just sign-extended before entering.
    function automatic logic [31:0] f_signed_to_float_SHARED
      (input logic signed [XXT_ACCUM_WIDTH-1:0] in);
        
        logic [XXT_ACCUM_WIDTH-1:0] in_abs;
        int lead_one_pos;
        logic [7:0] exponent;
        logic [22:0] mantissa;
        logic sign;
        
        if (in == '0) return 32'h00000000;

        sign = in[XXT_ACCUM_WIDTH-1];
        in_abs = sign ? -in : in;

        lead_one_pos = 0;
        for (integer k = XXT_ACCUM_WIDTH - 1; k >= 0; k--) begin
            if (in_abs[k]) begin
                lead_one_pos = k;
                break;
            end
        end

        exponent = lead_one_pos + 127;
        
        if (lead_one_pos >= 23)
            mantissa = in_abs >>> (lead_one_pos - 23);
        else
            mantissa = in_abs << (23 - lead_one_pos);
            
        return {sign, exponent, mantissa[22:0]};
    endfunction

endmodule