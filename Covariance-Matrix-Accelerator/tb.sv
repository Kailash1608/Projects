
`timescale 1ns / 1ps

module tb_covariance_matrix_single_pass_float;

    // Parameters
    localparam DATA_WIDTH = 16;
    localparam DIMENSIONS = 3;
    localparam SAMPLES = 4;
    localparam CLK_PERIOD = 10;
    localparam TOTAL_RESULTS = DIMENSIONS*DIMENSIONS + DIMENSIONS;
    localparam real EPSILON = 1.0e-4;

    // Signals
    bit clk = 0;
    logic rst, start, data_valid;
    logic signed [DATA_WIDTH-1:0] data_in;

    wire done;
    wire [31:0] result_out;
    wire [4:0] result_index;
    wire result_valid;

    // Input dataset
    logic signed [DATA_WIDTH-1:0]
        input_data [0:SAMPLES-1][0:DIMENSIONS-1];

    // Verification variables
    real received_results [0:TOTAL_RESULTS-1];
    real expected_sum [0:DIMENSIONS-1];
    real expected_xxt [0:DIMENSIONS-1][0:DIMENSIONS-1];
    real expected_cov [0:DIMENSIONS-1][0:DIMENSIONS-1];
    real dut_cov [0:DIMENSIONS-1][0:DIMENSIONS-1];

    real temp;
    real error_value;

    integer i, j, k;
    integer result_idx;
    logic test_passed;

    // DUT
    covariance_matrix_single_pass_float_OPT #(
        .DATA_WIDTH(DATA_WIDTH),
        .DIMENSIONS(DIMENSIONS),
        .SAMPLES(SAMPLES)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .data_in(data_in),
        .data_valid(data_valid),
        .done(done),
        .result_out(result_out),
        .result_index(result_index),
        .result_valid(result_valid)
    );

    // Clock: 100 MHz
    always #(CLK_PERIOD/2) clk = ~clk;

    // Absolute value
    function real abs_real(input real value);
        if (value < 0.0)
            abs_real = -value;
        else
            abs_real = value;
    endfunction

    // Capture serialized IEEE 754 outputs
    always @(posedge clk) begin
        if (result_valid && result_index < TOTAL_RESULTS)
            received_results[result_index] =
                $bitstoshortreal(result_out);
    end

    // Send three dimensions of one sample
    task feed_data(input integer d1, d2, d3);
        begin
            data_in = d1;
            data_valid = 1'b1;
            #(CLK_PERIOD);

            data_in = d2;
            data_valid = 1'b1;
            #(CLK_PERIOD);

            data_in = d3;
            data_valid = 1'b1;
            #(CLK_PERIOD);

            data_valid = 1'b0;
        end
    endtask

    initial begin
        $display("----------------------------------------");
        $display("Starting Covariance Matrix Testbench");
        $display("DATA_WIDTH=%0d, DIMENSIONS=%0d, SAMPLES=%0d",
                 DATA_WIDTH, DIMENSIONS, SAMPLES);
        $display("----------------------------------------");

        // 1. Initialize input data
        input_data[0][0]=1; input_data[0][1]=1; input_data[0][2]=1;
        input_data[1][0]=1; input_data[1][1]=1; input_data[1][2]=1;
        input_data[2][0]=3; input_data[2][1]=7; input_data[2][2]=11;
        input_data[3][0]=4; input_data[3][1]=8; input_data[3][2]=12;

        // 2. Calculate expected sums and cross-products
        for (i=0; i<DIMENSIONS; i=i+1) begin
            expected_sum[i] = 0.0;

            for (j=0; j<DIMENSIONS; j=j+1)
                expected_xxt[i][j] = 0.0;
        end

        for (k=0; k<SAMPLES; k=k+1) begin
            for (i=0; i<DIMENSIONS; i=i+1) begin
                expected_sum[i] =
                    expected_sum[i] + $itor(input_data[k][i]);

                for (j=0; j<DIMENSIONS; j=j+1) begin
                    expected_xxt[i][j] =
                        expected_xxt[i][j] +
                        ($itor(input_data[k][i]) *
                         $itor(input_data[k][j]));
                end
            end
        end

        // Expected population covariance
        for (i=0; i<DIMENSIONS; i=i+1) begin
            for (j=0; j<DIMENSIONS; j=j+1) begin
                expected_cov[i][j] =
                    (expected_xxt[i][j] -
                    (expected_sum[i]*expected_sum[j])/SAMPLES)
                    / SAMPLES;
            end
        end

        // 3. Reset and start DUT
        rst = 1'b1;
        start = 1'b0;
        data_in = '0;
        data_valid = 1'b0;

        for (i=0; i<TOTAL_RESULTS; i=i+1)
            received_results[i] = 0.0;

        #(CLK_PERIOD*2);
        rst = 1'b0;
        #(CLK_PERIOD);

        start = 1'b1;
        #(CLK_PERIOD);
        start = 1'b0;

        $display("Sending input samples...");

        // 4. Feed all samples
        for (k=0; k<SAMPLES; k=k+1)
            feed_data(input_data[k][0],
                      input_data[k][1],
                      input_data[k][2]);

        // 5. Wait for DUT completion
        wait (done === 1'b1);
        #(CLK_PERIOD*2);

        // 6. Reconstruct XXT matrix and sums
        result_idx = 0;

        for (i=0; i<DIMENSIONS; i=i+1) begin
            for (j=0; j<DIMENSIONS; j=j+1) begin
                dut_cov[i][j] = received_results[result_idx];
                result_idx = result_idx + 1;
            end
        end

        // The final three outputs are dimension sums.
        // Store them in expected_sum temporarily no longer needed
        // for the expected covariance calculation.
        for (i=0; i<DIMENSIONS; i=i+1) begin
            expected_sum[i] = received_results[result_idx];
            result_idx = result_idx + 1;
        end

        // 7. Calculate covariance from DUT outputs and compare
        test_passed = 1'b1;

        for (i=0; i<DIMENSIONS; i=i+1) begin
            for (j=0; j<DIMENSIONS; j=j+1) begin
                temp = (dut_cov[i][j] -
                       (expected_sum[i]*expected_sum[j])/SAMPLES)
                       / SAMPLES;

                error_value = temp - expected_cov[i][j];

                if (abs_real(error_value) > EPSILON)
                    test_passed = 1'b0;
            end
        end

        // 8. Print verification result
        if (test_passed)
            $display("\nSUCCESS: Test Passed! All results match.");
        else
            $display("\nERROR: Test Failed!");

        $display("\n--- Covariance Matrix ---");

        for (i=0; i<DIMENSIONS; i=i+1) begin
            $write("[ ");

            for (j=0; j<DIMENSIONS; j=j+1) begin
                temp = (dut_cov[i][j] -
                       (expected_sum[i]*expected_sum[j])/SAMPLES)
                       / SAMPLES;

                $write("%10.5f ", temp);
            end

            $display("]");
        end

        $display("\nTEST COMPLETED");
        $finish;
    end

endmodule
