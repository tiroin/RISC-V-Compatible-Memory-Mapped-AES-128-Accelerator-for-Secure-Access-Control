# GTKWave signals to add

Open `wave_v2.vcd` with GTKWave, then add these top-level debug signals:

```text
aes_start_dbg
aes_busy_dbg
aes_done_dbg
aes_key_dbg
aes_plaintext_dbg
aes_ciphertext_dbg
aes_latency_cycles
unlock
denied
alarm
fail_count
system_locked
```

The real AES core instance is inside the hierarchy:

```text
tb_aes_system.dut.u_aes_mmio_wrapper.u_aes128_core
```

The debug signals are exposed to top level only to make waveform screenshots easier.
