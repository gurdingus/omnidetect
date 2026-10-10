# bme688_train_and_save.py

import numpy as np
import pandas as pd
import time
import joblib

from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report

# Try XGBoost, fallback to RandomForest
try:
    from xgboost import XGBClassifier
    MODEL_TYPE = "xgboost"
except ImportError:
    from sklearn.ensemble import RandomForestClassifier
    MODEL_TYPE = "random_forest"

# -----------------------------
# Step 1: Synthetic Data Generator
# -----------------------------
np.random.seed(42)

def generate_sample(label):
    base_resistance = np.random.normal(100000, 10000)

    if label == 1:  # cancer class
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

def create_dataset(n_samples_per_class=5000):
    print("\n[1/5] Generating dataset...")
    start = time.time()

    data = []
    total = n_samples_per_class * 2

    for i in range(n_samples_per_class):
        data.append(generate_sample(0))
        data.append(generate_sample(1))

        if (i + 1) % 1000 == 0:
            print(f"  Generated {2*(i+1)} / {total} samples")

    df = pd.DataFrame(data)

    print(f"✔ Done in {time.time() - start:.2f}s")
    print(f"  Shape: {df.shape}")
    return df

# -----------------------------
# Step 2: Split Data
# -----------------------------
def prepare_data(df):
    print("\n[2/5] Splitting data...")
    start = time.time()

    X = df.drop("label", axis=1)
    y = df["label"]

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )

    print(f"✔ Done in {time.time() - start:.2f}s")
    print(f"  Train: {len(X_train)}, Test: {len(X_test)}")

    return X_train, X_test, y_train, y_test

# -----------------------------
# Step 3: Train Model
# -----------------------------
def train_model(X_train, y_train):
    print("\n[3/5] Training model...")
    start = time.time()

    if MODEL_TYPE == "xgboost":
        print("  Using XGBoost")
        model = XGBClassifier(
            n_estimators=200,
            max_depth=5,
            learning_rate=0.1,
            eval_metric="logloss"
        )
    else:
        print("  Using RandomForest")
        model = RandomForestClassifier(
            n_estimators=200,
            random_state=42,
            verbose=1
        )

    model.fit(X_train, y_train)

    print(f"✔ Training complete in {time.time() - start:.2f}s")
    return model

# -----------------------------
# Step 4: Evaluate
# -----------------------------
def evaluate(model, X_test, y_test):
    print("\n[4/5] Evaluating...")
    start = time.time()

    y_pred = model.predict(X_test)

    print(f"✔ Done in {time.time() - start:.2f}s")
    print("\n--- RESULTS ---")
    print("Model:", MODEL_TYPE)
    print("Accuracy:", accuracy_score(y_test, y_pred))
    print("\nClassification Report:\n")
    print(classification_report(y_test, y_pred))

# -----------------------------
# Step 5: Save + Load Model
# -----------------------------
def save_model(model, filename="bme688_model.pkl"):
    print("\n[5/5] Saving model...")
    joblib.dump(model, filename)
    print(f"✔ Saved as {filename}")

def load_model(filename="bme688_model.pkl"):
    print("\nReloading model to verify...")
    model = joblib.load(filename)
    print("✔ Model loaded successfully")
    return model

# -----------------------------
# Main
# -----------------------------
def main():
    total_start = time.time()
    print("=== BME688 TRAIN + SAVE PIPELINE ===")

    df = create_dataset()

    # Save dataset
    df.to_csv("bme688_dataset.csv", index=False)
    print("✔ Dataset saved as bme688_dataset.csv")

    X_train, X_test, y_train, y_test = prepare_data(df)

    model = train_model(X_train, y_train)

    evaluate(model, X_test, y_test)

    save_model(model)

    # Optional: reload to confirm it works
    model = load_model()

    print(f"\n=== DONE in {time.time() - total_start:.2f}s ===")

if __name__ == "__main__":
    main()
