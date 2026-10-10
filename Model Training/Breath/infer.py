# bme688_inference.py

import numpy as np
import pandas as pd
import joblib

# -----------------------------
# Load trained model
# -----------------------------
def load_model(filename="bme688_model.pkl"):
    print("Loading model...")
    model = joblib.load(filename)
    print("✔ Model loaded")
    return model

# -----------------------------
# Example: Generate a test sample
# (Replace this with real sensor data later)
# -----------------------------
def generate_test_sample():
    base_resistance = np.random.normal(100000, 10000)
    noise = np.random.normal(0, 2000, 50)
    signal = base_resistance + noise

    sample = {
        "gas_mean": np.mean(signal),
        "gas_std": np.std(signal),
        "gas_min": np.min(signal),
        "gas_max": np.max(signal),
        "gas_slope": signal[-1] - signal[0],
        "temp": np.random.normal(34, 1),
        "humidity": np.random.normal(90, 5),
        "pressure": np.random.normal(1013, 5),
    }

    return sample

# -----------------------------
# Run inference
# -----------------------------
def predict(model, sample):
    df = pd.DataFrame([sample])

    prediction = model.predict(df)[0]

    if hasattr(model, "predict_proba"):
        prob = model.predict_proba(df)[0][1]
    else:
        prob = None

    print("\n--- PREDICTION ---")
    print("Input:", sample)
    print("Class:", prediction, "(1 = cancer, 0 = healthy)")

    if prob is not None:
        print("Confidence (cancer probability):", round(prob, 3))

    return prediction

# -----------------------------
# Main
# -----------------------------
def main():
    model = load_model()

    print("\nGenerating test sample...")
    sample = generate_test_sample()

    predict(model, sample)

if __name__ == "__main__":
    main()
