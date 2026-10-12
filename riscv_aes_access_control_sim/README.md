# RISC-V-Compatible AES-128 Access-Control Accelerator Simulation

## Project Title

**Simulation and Verification of a RISC-V-Compatible AES-128 Hardware Accelerator for Secure Access Control**

## Summary

This project implements a memory-mapped AES-128 hardware accelerator and access-control logic in SystemVerilog. The design is intended to be integrated into a RISC-V SoC as an MMIO peripheral. Because no FPGA board is required, the current version is verified using RTL simulation.

The testbench acts like a CPU bus master:

1. writes AES key registers,
2. writes plaintext/password registers,
3. starts the AES accelerator,
4. polls the status register,
5. reads ciphertext registers,
6. checks access-control output.

## Architecture

```text
Testbench / CPU Emulator
        |
        v
Simple MMIO Bus
        |
        v
AES MMIO Wrapper
        |
        v
AES-128 Hardware Core
        |
        v
Access-Control Logic
        |
        +--> unlock / denied / alarm / system_locked
```

## Main Features

- AES-128 encrypt-only hardware core
- Memory-mapped AES register interface
- RISC-V-compatible peripheral style
- Access-control decision logic
- Lockout after three failed attempts
- AES standard test-vector verification
- VCD waveform generation

## Register Map

See [`docs/register_map.md`](docs/register_map.md).

## Simulation Requirements

Install Icarus Verilog and GTKWave:

```bash
sudo apt update
sudo apt install iverilog gtkwave
```

## Run Simulation

From the project root:

```bash
bash scripts/run_iverilog.sh
```

Expected output includes:

```text
AES TEST PASS
ACCESS GRANTED TEST PASS
LOCKOUT TEST PASS
ALL SIMULATION TESTS FINISHED
```

Open waveform:

```bash
gtkwave wave.vcd
```

## AES Test Vector

```text
Key:
000102030405060708090a0b0c0d0e0f

Plaintext:
00112233445566778899aabbccddeeff

Expected Ciphertext:
69c4e0d86a7b0430d8cdb78070b4c55a
```

## Correct Password Demo

Correct password is represented as ASCII `123456` padded with zeros to 16 bytes:

```text
31323334353600000000000000000000
```

Expected ciphertext:

```text
61eff851e7f93fef09c49561ffbc3878
```

## How to Present This Project

Use this description:

> Designed and verified a RISC-V-compatible memory-mapped AES-128 hardware accelerator for secure access control. Developed SystemVerilog RTL modules, MMIO register interface, access-control logic, and simulation testbenches. Verified the design using AES standard test vectors and access-control scenarios.

## Future Work

- Integrate with PicoRV32 or VexRiscv CPU
- Add UART input for password entry
- Map output to GPIO LEDs/buzzer
- Run synthesis for Artix-7 or Cyclone FPGA target
- Compare software AES vs hardware AES latency


## Debug waveform outputs

This debug package exposes the AES internal handshake and datapath at the top-level waveform:

```text
aes_start_dbg
aes_busy_dbg
aes_done_dbg
aes_key_dbg
aes_plaintext_dbg
aes_ciphertext_dbg
aes_latency_cycles
```

The actual AES core is still instantiated at:

```text
tb_aes_system.dut.u_aes_mmio_wrapper.u_aes128_core
```
