#!/usr/bin/env python3
import sys

def generate_pulses(freq=60.0, amp=1.0, width_us=100.0):
    total_energy_uJ = (amp**2) * (width_us * 1e-6) * freq * 1e6
    return {"delivered_frequency_hz": freq, "pulse_width_us": width_us, "energy_uJ": round(total_energy_uJ, 2)}

def main():
    pulses = generate_pulses()
    print(f"   [Stimulator Agent] Emitting stimulation pulses: freq={pulses['delivered_frequency_hz']}Hz, pulse_width={pulses['pulse_width_us']}us, energy={pulses['energy_uJ']}uJ", flush=True)

if __name__ == "__main__":
    main()

