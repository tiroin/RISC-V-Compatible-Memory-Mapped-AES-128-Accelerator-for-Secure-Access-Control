// ================================================================
// Top-level simulation system - V2
// Testbench acts as bus master / CPU.
//
// Includes:
// - AES MMIO wrapper
// - Dynamic challenge-response access-control checker
// ================================================================

module top_sim (
    input  logic        clk,
    input  logic        rst,

    input  logic        bus_valid,
    input  logic        bus_we,
    input  logic [31:0] bus_addr,
    input  logic [31:0] bus_wdata,
    output logic [31:0] bus_rdata,
    output logic        bus_ready,

    input  logic        check_valid,
    input  logic [127:0] check_ciphertext,
    input  logic [127:0] expected_ciphertext,

    output logic        unlock,
    output logic        denied,
    output logic        alarm,
    output logic        system_locked,
    output logic [1:0]  fail_count,
    output logic [31:0] aes_latency_cycles,

    // AES debug signals exposed at top level for GTKWave
    output logic        aes_start_dbg,
    output logic        aes_busy_dbg,
    output logic        aes_done_dbg,
    output logic [127:0] aes_key_dbg,
    output logic [127:0] aes_plaintext_dbg,
    output logic [127:0] aes_ciphertext_dbg
);

    logic aes_done_unused;

    aes_mmio_wrapper u_aes_mmio_wrapper (
        .clk           (clk),
        .rst           (rst),
        .bus_valid     (bus_valid),
        .bus_we        (bus_we),
        .bus_addr      (bus_addr),
        .bus_wdata     (bus_wdata),
        .bus_rdata     (bus_rdata),
        .bus_ready          (bus_ready),
        .aes_done_o         (aes_done_unused),
        .aes_latency_o      (aes_latency_cycles),
        .aes_start_dbg      (aes_start_dbg),
        .aes_busy_dbg       (aes_busy_dbg),
        .aes_done_dbg       (aes_done_dbg),
        .aes_key_dbg        (aes_key_dbg),
        .aes_plaintext_dbg  (aes_plaintext_dbg),
        .aes_ciphertext_dbg (aes_ciphertext_dbg)
    );

    access_control u_access_control (
        .clk                 (clk),
        .rst                 (rst),
        .check_valid         (check_valid),
        .ciphertext          (check_ciphertext),
        .expected_ciphertext (expected_ciphertext),
        .unlock              (unlock),
        .denied              (denied),
        .alarm               (alarm),
        .system_locked       (system_locked),
        .fail_count          (fail_count)
    );

endmodule
