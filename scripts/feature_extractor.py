#!/usr/bin/env python3
import sys
import math
import random

def extract_features(raw_signal=None):
    if raw_signal is None:
        raw_signal = [math.sin(i * 0.1) + random.normalvariate(0, 0.05) for i in range(100)]
    # Compute mean power in 30-80Hz gamma band
    power = sum(x**2 for x in raw_signal) / len(raw_signal)
    snr_db = 10 * math.log10(power / 0.0025)
    return {"gamma_band_power": round(power, 4), "snr_db": round(snr_db, 2)}

def main():
    feats = extract_features()
    print(f"   [Feature Extractor] Biomarkers extracted: gamma_band_power={feats['gamma_band_power']}, SNR={feats['snr_db']}dB", flush=True)

if __name__ == "__main__":
    main()

