// ================================================================
// Memory-mapped AES-128 wrapper
// Compatible with a simple RISC-V-style MMIO bus.
// Testbench can act as CPU bus master.
//
// V2 upgrade:
// - Adds AES latency counter register at 0x40
// - Keeps done sticky until next start command
// ================================================================

module aes_mmio_wrapper (
    input  logic        clk,
    input  logic        rst,

    input  logic        bus_valid,
    input  logic        bus_we,
    input  logic [31:0] bus_addr,
    input  logic [31:0] bus_wdata,
    output logic [31:0] bus_rdata,
    output logic        bus_ready,

    output logic        aes_done_o,
    output logic [31:0] aes_latency_o,

    // Debug outputs for waveform viewing
    output logic        aes_start_dbg,
    output logic        aes_busy_dbg,
    output logic        aes_done_dbg,
    output logic [127:0] aes_key_dbg,
    output logic [127:0] aes_plaintext_dbg,
    output logic [127:0] aes_ciphertext_dbg
);

    localparam CTRL    = 8'h00;
    localparam STATUS  = 8'h04;
    localparam KEY0    = 8'h10;
    localparam KEY1    = 8'h14;
    localparam KEY2    = 8'h18;
    localparam KEY3    = 8'h1c;
    localparam PT0     = 8'h20;
    localparam PT1     = 8'h24;
    localparam PT2     = 8'h28;
    localparam PT3     = 8'h2c;
    localparam CT0     = 8'h30;
    localparam CT1     = 8'h34;
    localparam CT2     = 8'h38;
    localparam CT3     = 8'h3c;
    localparam LATENCY = 8'h40;

    logic [127:0] key_reg;
    logic [127:0] pt_reg;
    logic [127:0] ct_wire;
    logic         aes_start;
    logic         aes_busy;
    logic         aes_done;
    logic         done_sticky;

    logic         measure_active;
    logic [31:0] latency_counter;
    logic [31:0] latency_last;

    assign bus_ready          = bus_valid;
    assign aes_done_o         = done_sticky;
    assign aes_latency_o      = latency_last;

    assign aes_start_dbg      = aes_start;
    assign aes_busy_dbg       = aes_busy;
    assign aes_done_dbg       = aes_done;
    assign aes_key_dbg        = key_reg;
    assign aes_plaintext_dbg  = pt_reg;
    assign aes_ciphertext_dbg = ct_wire;

    aes128_core u_aes128_core (
        .clk        (clk),
        .rst        (rst),
        .start      (aes_start),
        .key        (key_reg),
        .plaintext  (pt_reg),
        .ciphertext (ct_wire),
        .busy       (aes_busy),
        .done       (aes_done)
    );

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            key_reg         <= 128'd0;
            pt_reg          <= 128'd0;
            done_sticky     <= 1'b0;
            aes_start       <= 1'b0;
            measure_active  <= 1'b0;
            latency_counter <= 32'd0;
            latency_last    <= 32'd0;
        end else begin
            aes_start <= 1'b0;

            // Count cycles between a start command and AES done.
            if (measure_active)
                latency_counter <= latency_counter + 32'd1;

            if (aes_done) begin
                done_sticky    <= 1'b1;
                measure_active <= 1'b0;
                latency_last   <= latency_counter;
            end

            if (bus_valid && bus_we) begin
                case (bus_addr[7:0])
                    CTRL: begin
                        if (bus_wdata[0]) begin
                            aes_start       <= 1'b1;
                            done_sticky     <= 1'b0;
                            measure_active  <= 1'b1;
                            latency_counter <= 32'd0;
                            latency_last    <= 32'd0;
                        end
                    end
                    KEY0: key_reg[127:96] <= bus_wdata;
                    KEY1: key_reg[95:64]  <= bus_wdata;
                    KEY2: key_reg[63:32]  <= bus_wdata;
                    KEY3: key_reg[31:0]   <= bus_wdata;
                    PT0:  pt_reg[127:96]  <= bus_wdata;
                    PT1:  pt_reg[95:64]   <= bus_wdata;
                    PT2:  pt_reg[63:32]   <= bus_wdata;
                    PT3:  pt_reg[31:0]    <= bus_wdata;
                    default: ;
                endcase
            end
        end
    end

    // Icarus Verilog may warn about constant part-selects inside always_comb.
    // always @* keeps the logic combinational and is friendlier to Icarus.
    always @* begin
        bus_rdata = 32'd0;
        case (bus_addr[7:0])
            CTRL:    bus_rdata = 32'd0;
            STATUS:  bus_rdata = {30'd0, done_sticky, aes_busy}; // bit0=busy, bit1=done
            KEY0:    bus_rdata = key_reg[127:96];
            KEY1:    bus_rdata = key_reg[95:64];
            KEY2:    bus_rdata = key_reg[63:32];
            KEY3:    bus_rdata = key_reg[31:0];
            PT0:     bus_rdata = pt_reg[127:96];
            PT1:     bus_rdata = pt_reg[95:64];
            PT2:     bus_rdata = pt_reg[63:32];
            PT3:     bus_rdata = pt_reg[31:0];
            CT0:     bus_rdata = ct_wire[127:96];
            CT1:     bus_rdata = ct_wire[95:64];
            CT2:     bus_rdata = ct_wire[63:32];
            CT3:     bus_rdata = ct_wire[31:0];
            LATENCY: bus_rdata = latency_last;
            default: bus_rdata = 32'hDEAD_BEEF;
        endcase
    end

endmodule
