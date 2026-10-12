#!/usr/bin/env bash
set -e

mkdir -p build
iverilog -g2012 \
  -o build/aes_system_sim_v2.out \
  rtl/aes128_core.sv \
  rtl/aes_mmio_wrapper.sv \
  rtl/challenge_builder.sv \
  rtl/access_control.sv \
  rtl/top_sim.sv \
  tb/tb_aes_system.sv

vvp build/aes_system_sim_v2.out

echo ""
echo "Waveform generated: wave_v2.vcd"
echo "Open with: gtkwave wave_v2.vcd"
