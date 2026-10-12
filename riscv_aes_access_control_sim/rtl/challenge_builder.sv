// ================================================================
// Challenge-response block builder
//
// For the simulation demo, the authentication plaintext block is:
//     challenge_block = password_block XOR nonce
//
// This makes the AES response change for each nonce. Therefore, an
// old ciphertext response cannot be replayed for a new challenge.
// ================================================================

module challenge_builder (
    input  logic [127:0] password_block,
    input  logic [127:0] nonce,
    output logic [127:0] challenge_block
);

    assign challenge_block = password_block ^ nonce;

endmodule
