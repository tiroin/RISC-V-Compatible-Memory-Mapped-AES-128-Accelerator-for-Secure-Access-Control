# Report Outline - V2

## Title
Simulation and Verification of a RISC-V-Compatible AES-128 Hardware Accelerator with Challenge-Response Authentication for Secure Access Control

## 1. Introduction
IoT access-control systems require secure authentication. This project designs and verifies a RISC-V-compatible memory-mapped AES-128 hardware accelerator for secure access control. Since no physical FPGA board is available, the design is verified through RTL simulation.

## 2. System Architecture
The system contains:
- AES-128 hardware accelerator
- Memory-mapped register wrapper
- Challenge-response block builder
- Dynamic access-control logic
- CPU-like bus-master testbench

## 3. Challenge-Response Authentication
Instead of encrypting a fixed password block, V2 constructs a challenge block:

```text
challenge_block = password_block XOR nonce
response        = AES_Encrypt(challenge_block, key)
```

This prevents a simple replay attack because the same password produces a different AES response for every nonce.

## 4. Register Map
Describe CTRL, STATUS, KEY, PT, CT, and LATENCY registers.

## 5. Verification Plan
The RTL testbench verifies:
1. AES-128 standard test vector
2. Correct challenge-response authentication
3. Anti-replay rejection when an old response is used with a new nonce
4. Lockout after three wrong challenge responses
5. AES latency counter readback

## 6. Expected Simulation Results
Expected terminal results:

```text
AES TEST PASS
CHALLENGE ACCESS TEST PASS
ANTI-REPLAY TEST PASS
LOCKOUT TEST PASS
ALL V2 SIMULATION TESTS FINISHED
```

## 7. Discussion
The design demonstrates SoC-level peripheral integration, cryptographic acceleration, MMIO register control, and security-oriented authentication logic. It is synthesis-ready and can be connected to a RISC-V CPU such as PicoRV32 or VexRiscv in a future FPGA implementation.

## 8. Future Work
- Integrate PicoRV32 as the actual RISC-V CPU
- Add UART input for password and nonce
- Run synthesis on an Artix-7 or Cyclone FPGA target
- Add AES-CBC or AES-GCM mode
- Add side-channel countermeasures
