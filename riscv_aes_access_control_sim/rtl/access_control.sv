// ================================================================
// Secure access-control decision logic - V2
//
// V2 upgrade:
// - Expected ciphertext is dynamic instead of a fixed parameter.
// - This supports challenge-response authentication, where each
//   nonce produces a different expected response.
// - Grants unlock on match.
// - Raises alarm after 3 failed attempts.
// ================================================================

module access_control #(
    parameter integer MAX_FAILED_ATTEMPTS = 3
)(
    input  logic         clk,
    input  logic         rst,
    input  logic         check_valid,
    input  logic [127:0] ciphertext,
    input  logic [127:0] expected_ciphertext,
    output logic         unlock,
    output logic         denied,
    output logic         alarm,
    output logic         system_locked,
    output logic [1:0]   fail_count
);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            unlock        <= 1'b0;
            denied        <= 1'b0;
            alarm         <= 1'b0;
            system_locked <= 1'b0;
            fail_count    <= 2'd0;
        end else begin
            // Outputs are held until the next authentication attempt.
            // This makes waveform/debug easier in simulation.
            if (check_valid && !system_locked) begin
                if (ciphertext == expected_ciphertext) begin
                    unlock     <= 1'b1;
                    denied     <= 1'b0;
                    fail_count <= 2'd0;
                    alarm      <= 1'b0;
                end else begin
                    unlock <= 1'b0;
                    denied <= 1'b1;
                    if (fail_count == 2'd2) begin
                        fail_count    <= 2'd3;
                        alarm         <= 1'b1;
                        system_locked <= 1'b1;
                    end else begin
                        fail_count <= fail_count + 2'd1;
                    end
                end
            end
        end
    end

endmodule
