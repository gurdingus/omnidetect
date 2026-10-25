# RIPENESS PREDICTION
# -----------------------------
def predict_ripeness(crop_img, model, class_names):
    img = Image.fromarray(cv2.cvtColor(crop_img, cv2.COLOR_BGR2RGB))
    img = transform(img).unsqueeze(0).to(DEVICE)
    with torch.no_grad():
        outputs = model(img)
        probs = F.softmax(outputs, dim=1)
        conf, pred = torch.max(probs, 1)
    return class_names[pred.item()], conf.item()


def map_ripeness_label(pred_label):
    label_norm = pred_label.lower().replace("_", "-")
    if label_norm in ["ripe", "semi-ripe"]:
        return "ripe"
    return pred_label


# -----------------------------
# PROCESS IMAGE (OpenCV BGR array)
# -----------------------------
def process_image(image):
    if image is None or image.size == 0:
        raise ValueError("process_image() received an empty image")

    results = yolo_model(image)[0]
    detections = []
    height, width = image.shape[:2]

    for box in results.boxes:
        cls_id = int(box.cls[0])
        label = results.names[cls_id]
        if label not in ["banana", "apple"]:
            continue

        x1, y1, x2, y2 = map(int, box.xyxy[0])
        x1, x2 = max(0, x1), min(width, x2)
        y1, y2 = max(0, y1), min(height, y2)
        crop = image[y1:y2, x1:x2]
        if crop.size == 0:
            continue

        if label == "banana":
            ripeness, conf = predict_ripeness(crop, banana_model, BANANA_CLASSES)
        else:
            ripeness, conf = predict_ripeness(crop, apple_model, APPLE_CLASSES)

        detections.append({
            "label": label,
            "bbox": (x1, y1, x2, y2),
            "ripeness": ripeness,
            "confidence": conf,
            "crop": crop,
        })

    return image, detections


# -----------------------------
# VISUALIZATION
# -----------------------------
def visualize(image, detections):
    display_image = image.copy()
    for i, det in enumerate(detections):
        x1, y1, x2, y2 = det["bbox"]
        text = f'{det["label"]} ({map_ripeness_label(det["ripeness"])}: {det["confidence"]:.2f})'
        cv2.rectangle(display_image, (x1, y1), (x2, y2), (0, 255, 0), 2)
        cv2.putText(display_image, text, (x1, max(y1 - 10, 20)),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 0), 2)
        cv2.imshow(f'{det["label"]}_{i}', det["crop"])

    cv2.imshow("Detections", display_image)
    cv2.waitKey(0)
    cv2.destroyAllWindows()


# -----------------------------
# CLASSIFY IMAGE
# -----------------------------
def classify_image(image):
    image, detections = process_image(image)
    print("\nDetected Fruits:")
    if not detections:
        print("No bananas or apples detected.")
    for det in detections:
        display_label = map_ripeness_label(det["ripeness"])
        print(f'{det["label"]} → {display_label} (confidence: {det["confidence"]:.2f})')
    # visualize(image, detections)
    return detections


# -----------------------------
# ENTRY POINT
# -----------------------------
if __name__ == "__main__":
    if DEMO_MODE:
        print("Running in DEMO mode...")
        image = cv2.imread(DEMO_IMAGE_PATH)
        if image is None:
            raise FileNotFoundError(f"Could not load demo image: {DEMO_IMAGE_PATH}")
    else:
        print(f"Fetching camera image from {PICTURE_URL}...")
        response = requests.get(PICTURE_URL, timeout=15)
        response.raise_for_status()
        image_bytes = np.frombuffer(response.content, dtype=np.uint8)
        image = cv2.imdecode(image_bytes, cv2.IMREAD_COLOR)
        if image is None:
            raise ValueError(f"HTTP response did not contain a valid image: {PICTURE_URL}")

    classify_image(image)

