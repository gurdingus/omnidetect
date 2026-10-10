import numpy as np
import pandas as pd

np.random.seed(42)

def generate_sample(label):
    base_resistance = np.random.normal(100000, 10000)

    if label == 1:  # cancer
        base_resistance *= np.random.uniform(0.6, 0.85)

    noise = np.random.normal(0, 2000, 50)
    signal = base_resistance + noise

    return {
        "gas_mean": np.mean(signal),
        "gas_std": np.std(signal),
        "gas_min": np.min(signal),
        "gas_max": np.max(signal),
        "gas_slope": signal[-1] - signal[0],
        "temp": np.random.normal(34, 1),
        "humidity": np.random.normal(90, 5),
        "pressure": np.random.normal(1013, 5),
        "label": label
    }

data = []
for _ in range(5000):
    data.append(generate_sample(0))
    data.append(generate_sample(1))

df = pd.DataFrame(data)
df.to_csv("bme688_dataset.csv", index=False)

print(df.head())
