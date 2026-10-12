# Memory-Mapped AES Accelerator Register Map - V2

The AES accelerator is exposed as a RISC-V-compatible memory-mapped peripheral.
The testbench emulates CPU bus transactions using `bus_valid`, `bus_we`, `bus_addr`, `bus_wdata`, and `bus_rdata`.

| Offset | Register | Direction | Description |
|---:|---|---|---|
| `0x00` | `CTRL` | W | Bit 0 = start AES encryption |
| `0x04` | `STATUS` | R | Bit 0 = busy, bit 1 = done |
| `0x10` | `KEY0` | R/W | AES key bits `[127:96]` |
| `0x14` | `KEY1` | R/W | AES key bits `[95:64]` |
| `0x18` | `KEY2` | R/W | AES key bits `[63:32]` |
| `0x1C` | `KEY3` | R/W | AES key bits `[31:0]` |
| `0x20` | `PT0` | R/W | Plaintext/challenge bits `[127:96]` |
| `0x24` | `PT1` | R/W | Plaintext/challenge bits `[95:64]` |
| `0x28` | `PT2` | R/W | Plaintext/challenge bits `[63:32]` |
| `0x2C` | `PT3` | R/W | Plaintext/challenge bits `[31:0]` |
| `0x30` | `CT0` | R | Ciphertext/response bits `[127:96]` |
| `0x34` | `CT1` | R | Ciphertext/response bits `[95:64]` |
| `0x38` | `CT2` | R | Ciphertext/response bits `[63:32]` |
| `0x3C` | `CT3` | R | Ciphertext/response bits `[31:0]` |
| `0x40` | `LATENCY` | R | Number of clock cycles measured for the latest AES operation |

## Authentication block construction

V2 uses a challenge-response concept:

```text
challenge_block = password_block XOR nonce
response        = AES_Encrypt(challenge_block, AES_key)
```

Because the nonce changes every authentication session, the AES response also changes.
An old response is rejected when replayed with a new nonce.
