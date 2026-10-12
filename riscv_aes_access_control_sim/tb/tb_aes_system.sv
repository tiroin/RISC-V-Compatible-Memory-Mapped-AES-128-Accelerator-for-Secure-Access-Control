`timescale 1ns/1ps

module tb_aes_system;

    localparam [31:0] CTRL    = 32'h0000_0000;
    localparam [31:0] STATUS  = 32'h0000_0004;
    localparam [31:0] KEY0    = 32'h0000_0010;
    localparam [31:0] KEY1    = 32'h0000_0014;
    localparam [31:0] KEY2    = 32'h0000_0018;
    localparam [31:0] KEY3    = 32'h0000_001c;
    localparam [31:0] PT0     = 32'h0000_0020;
    localparam [31:0] PT1     = 32'h0000_0024;
    localparam [31:0] PT2     = 32'h0000_0028;
    localparam [31:0] PT3     = 32'h0000_002c;
    localparam [31:0] CT0     = 32'h0000_0030;
    localparam [31:0] CT1     = 32'h0000_0034;
    localparam [31:0] CT2     = 32'h0000_0038;
    localparam [31:0] CT3     = 32'h0000_003c;
    localparam [31:0] LATENCY = 32'h0000_0040;

    localparam [127:0] AES_KEY = 128'h000102030405060708090a0b0c0d0e0f;

    // password = ASCII "123456" + zero padding to 16 bytes
    localparam [127:0] CORRECT_PASSWORD_BLOCK = 128'h31323334353600000000000000000000;
    localparam [127:0] WRONG_PASSWORD_1       = 128'h31313131313100000000000000000000; // "111111"
    localparam [127:0] WRONG_PASSWORD_2       = 128'h32323232323200000000000000000000; // "222222"
    localparam [127:0] WRONG_PASSWORD_3       = 128'h33333333333300000000000000000000; // "333333"

    localparam [127:0] NONCE_1 = 128'ha5a5a5a5_00000001_11223344_55667788;
    localparam [127:0] NONCE_2 = 128'h5a5a5a5a_00000002_88776655_44332211;

    logic clk;
    logic rst;

    logic        bus_valid;
    logic        bus_we;
    logic [31:0] bus_addr;
    logic [31:0] bus_wdata;
    logic [31:0] bus_rdata;
    logic        bus_ready;

    logic         check_valid;
    logic [127:0] check_ciphertext;
    logic [127:0] expected_ciphertext;
    logic         unlock;
    logic         denied;
    logic         alarm;
    logic         system_locked;
    logic [1:0]   fail_count;
    logic [31:0]  aes_latency_cycles;
    logic         aes_start_dbg;
    logic         aes_busy_dbg;
    logic         aes_done_dbg;
    logic [127:0] aes_key_dbg;
    logic [127:0] aes_plaintext_dbg;
    logic [127:0] aes_ciphertext_dbg;

    logic [127:0] challenge_password_block;
    logic [127:0] challenge_nonce;
    logic [127:0] challenge_block;

    challenge_builder u_challenge_builder (
        .password_block  (challenge_password_block),
        .nonce           (challenge_nonce),
        .challenge_block (challenge_block)
    );

    top_sim dut (
        .clk                (clk),
        .rst                (rst),
        .bus_valid          (bus_valid),
        .bus_we             (bus_we),
        .bus_addr           (bus_addr),
        .bus_wdata          (bus_wdata),
        .bus_rdata          (bus_rdata),
        .bus_ready          (bus_ready),
        .check_valid        (check_valid),
        .check_ciphertext   (check_ciphertext),
        .expected_ciphertext(expected_ciphertext),
        .unlock             (unlock),
        .denied             (denied),
        .alarm              (alarm),
        .system_locked      (system_locked),
        .fail_count         (fail_count),
        .aes_latency_cycles (aes_latency_cycles),
        .aes_start_dbg      (aes_start_dbg),
        .aes_busy_dbg       (aes_busy_dbg),
        .aes_done_dbg       (aes_done_dbg),
        .aes_key_dbg        (aes_key_dbg),
        .aes_plaintext_dbg  (aes_plaintext_dbg),
        .aes_ciphertext_dbg (aes_ciphertext_dbg)
    );

    always #5 clk = ~clk;

    task automatic init_inputs;
        begin
            bus_valid = 1'b0;
            bus_we = 1'b0;
            bus_addr = 32'd0;
            bus_wdata = 32'd0;
            check_valid = 1'b0;
            check_ciphertext = 128'd0;
            expected_ciphertext = 128'd0;
            challenge_password_block = 128'd0;
            challenge_nonce = 128'd0;
        end
    endtask

    task automatic reset_system;
        begin
            rst = 1'b1;
            init_inputs();
            repeat (5) @(negedge clk);
            rst = 1'b0;
            repeat (2) @(negedge clk);
        end
    endtask

    task automatic bus_write(input [31:0] addr, input [31:0] data);
        begin
            @(negedge clk);
            bus_valid <= 1'b1;
            bus_we    <= 1'b1;
            bus_addr  <= addr;
            bus_wdata <= data;
            @(negedge clk);
            bus_valid <= 1'b0;
            bus_we    <= 1'b0;
            bus_addr  <= 32'd0;
            bus_wdata <= 32'd0;
        end
    endtask

    task automatic bus_read(input [31:0] addr, output [31:0] data);
        begin
            @(negedge clk);
            bus_valid <= 1'b1;
            bus_we    <= 1'b0;
            bus_addr  <= addr;
            @(negedge clk);
            data = bus_rdata;
            bus_valid <= 1'b0;
            bus_addr  <= 32'd0;
        end
    endtask

    task automatic write_key(input [127:0] key);
        begin
            bus_write(KEY0, key[127:96]);
            bus_write(KEY1, key[95:64]);
            bus_write(KEY2, key[63:32]);
            bus_write(KEY3, key[31:0]);
        end
    endtask

    task automatic write_plaintext(input [127:0] pt);
        begin
            bus_write(PT0, pt[127:96]);
            bus_write(PT1, pt[95:64]);
            bus_write(PT2, pt[63:32]);
            bus_write(PT3, pt[31:0]);
        end
    endtask

    task automatic wait_done;
        reg [31:0] status_word;
        begin
            status_word = 32'd0;
            while (status_word[1] != 1'b1) begin
                bus_read(STATUS, status_word);
            end
        end
    endtask

    task automatic read_ciphertext(output [127:0] ct);
        reg [31:0] c0, c1, c2, c3;
        begin
            bus_read(CT0, c0);
            bus_read(CT1, c1);
            bus_read(CT2, c2);
            bus_read(CT3, c3);
            ct = {c0, c1, c2, c3};
        end
    endtask

    task automatic read_latency(output [31:0] cycles);
        begin
            bus_read(LATENCY, cycles);
        end
    endtask

    task automatic encrypt_block(input [127:0] pt, output [127:0] ct, output [31:0] cycles);
        begin
            write_key(AES_KEY);
            write_plaintext(pt);
            bus_write(CTRL, 32'h0000_0001);
            wait_done();
            read_ciphertext(ct);
            read_latency(cycles);
        end
    endtask

    task automatic build_challenge(input [127:0] password_block, input [127:0] nonce, output [127:0] block);
        begin
            challenge_password_block = password_block;
            challenge_nonce = nonce;
            #1;
            block = challenge_block;
        end
    endtask

    task automatic check_access(input [127:0] response_ct, input [127:0] expected_ct);
        begin
            @(negedge clk);
            check_ciphertext    <= response_ct;
            expected_ciphertext <= expected_ct;
            check_valid         <= 1'b1;
            @(negedge clk);
            check_valid         <= 1'b0;
            check_ciphertext    <= 128'd0;
            @(negedge clk);
        end
    endtask

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        init_inputs();

        $dumpfile("wave_v2.vcd");
        $dumpvars(0, tb_aes_system);

        reset_system();
        run_tests();

        $display("====================================================");
        $display("ALL V2 SIMULATION TESTS FINISHED");
        $display("====================================================");
        #50;
        $finish;
    end

    task automatic run_tests;
        reg [127:0] ct;
        reg [127:0] challenge1;
        reg [127:0] challenge2;
        reg [127:0] expected_nonce1;
        reg [127:0] expected_nonce2;
        reg [127:0] wrong_challenge;
        reg [127:0] wrong_ct;
        reg [31:0]  cycles;
        begin
            $display("====================================================");
            $display("TEST 1: AES-128 standard test vector + latency counter");
            $display("====================================================");
            encrypt_block(128'h00112233445566778899aabbccddeeff, ct, cycles);
            $display("Expected CT = 69c4e0d86a7b0430d8cdb78070b4c55a");
            $display("Got CT      = %032h", ct);
            $display("AES latency = %0d cycles", cycles);
            if (ct == 128'h69c4e0d86a7b0430d8cdb78070b4c55a)
                $display("AES TEST PASS");
            else begin
                $display("AES TEST FAIL");
                $fatal;
            end

            $display("\n====================================================");
            $display("TEST 2: Challenge-response authentication with nonce");
            $display("====================================================");
            build_challenge(CORRECT_PASSWORD_BLOCK, NONCE_1, challenge1);
            encrypt_block(challenge1, expected_nonce1, cycles);
            $display("Nonce #1          = %032h", NONCE_1);
            $display("Challenge block   = %032h", challenge1);
            $display("Expected response = %032h", expected_nonce1);
            $display("AES latency       = %0d cycles", cycles);
            check_access(expected_nonce1, expected_nonce1);
            $display("unlock=%0d denied=%0d alarm=%0d fail_count=%0d locked=%0d", unlock, denied, alarm, fail_count, system_locked);
            if (unlock !== 1'b1 || alarm !== 1'b0) begin
                $display("CHALLENGE ACCESS TEST FAIL");
                $fatal;
            end else begin
                $display("CHALLENGE ACCESS TEST PASS");
            end

            $display("\n====================================================");
            $display("TEST 3: Anti-replay test: old response rejected for new nonce");
            $display("====================================================");
            build_challenge(CORRECT_PASSWORD_BLOCK, NONCE_2, challenge2);
            encrypt_block(challenge2, expected_nonce2, cycles);
            $display("Nonce #2               = %032h", NONCE_2);
            $display("Expected response #2   = %032h", expected_nonce2);
            $display("Replayed old response  = %032h", expected_nonce1);
            if (expected_nonce1 == expected_nonce2) begin
                $display("ANTI-REPLAY TEST FAIL: nonce did not change response");
                $fatal;
            end
            check_access(expected_nonce1, expected_nonce2);
            $display("unlock=%0d denied=%0d alarm=%0d fail_count=%0d locked=%0d", unlock, denied, alarm, fail_count, system_locked);
            if (unlock !== 1'b0 || denied !== 1'b1) begin
                $display("ANTI-REPLAY TEST FAIL");
                $fatal;
            end else begin
                $display("ANTI-REPLAY TEST PASS");
            end

            // Reset before lockout test so the fail counter starts from 0.
            reset_system();

            $display("\n====================================================");
            $display("TEST 4: Three wrong challenge responses -> alarm and lockout");
            $display("====================================================");
            build_challenge(CORRECT_PASSWORD_BLOCK, NONCE_2, challenge2);
            encrypt_block(challenge2, expected_nonce2, cycles);

            build_challenge(WRONG_PASSWORD_1, NONCE_2, wrong_challenge);
            encrypt_block(wrong_challenge, wrong_ct, cycles);
            check_access(wrong_ct, expected_nonce2);
            $display("After wrong #1: unlock=%0d denied=%0d alarm=%0d fail_count=%0d locked=%0d", unlock, denied, alarm, fail_count, system_locked);

            build_challenge(WRONG_PASSWORD_2, NONCE_2, wrong_challenge);
            encrypt_block(wrong_challenge, wrong_ct, cycles);
            check_access(wrong_ct, expected_nonce2);
            $display("After wrong #2: unlock=%0d denied=%0d alarm=%0d fail_count=%0d locked=%0d", unlock, denied, alarm, fail_count, system_locked);

            build_challenge(WRONG_PASSWORD_3, NONCE_2, wrong_challenge);
            encrypt_block(wrong_challenge, wrong_ct, cycles);
            check_access(wrong_ct, expected_nonce2);
            $display("After wrong #3: unlock=%0d denied=%0d alarm=%0d fail_count=%0d locked=%0d", unlock, denied, alarm, fail_count, system_locked);

            if (alarm !== 1'b1 || system_locked !== 1'b1 || fail_count !== 2'd3) begin
                $display("LOCKOUT TEST FAIL");
                $fatal;
            end else begin
                $display("LOCKOUT TEST PASS");
            end
        end
    endtask

endmodule
