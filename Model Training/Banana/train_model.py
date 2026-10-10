import torch
import torch.nn as nn
import torch.optim as optim
from torchvision import datasets, transforms, models
from torch.utils.data import DataLoader
from tqdm import tqdm

# -------------------------
# CONFIG
# -------------------------

train_dir = "dataset/train"
val_dir = "dataset/val"

batch_size = 32
epochs = 20
learning_rate = 0.0001

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# -------------------------
# IMAGE TRANSFORMS
# -------------------------

train_transforms = transforms.Compose([
    transforms.Resize((224,224)),
    transforms.RandomHorizontalFlip(),
    transforms.RandomRotation(10),
    transforms.ColorJitter(brightness=0.2, contrast=0.2),
    transforms.ToTensor(),
])

val_transforms = transforms.Compose([
    transforms.Resize((224,224)),
    transforms.ToTensor(),
])

# -------------------------
# DATASETS
# -------------------------

train_dataset = datasets.ImageFolder(train_dir, transform=train_transforms)
val_dataset = datasets.ImageFolder(val_dir, transform=val_transforms)

train_loader = DataLoader(train_dataset, batch_size=batch_size, shuffle=True)
val_loader = DataLoader(val_dataset, batch_size=batch_size)

# Automatically detect number of classes
num_classes = len(train_dataset.classes)

print("Classes:", train_dataset.classes)
print("Class mapping:", train_dataset.class_to_idx)

# -------------------------
# MODEL
# -------------------------

model = models.efficientnet_b0(weights="IMAGENET1K_V1")

in_features = model.classifier[1].in_features
model.classifier[1] = nn.Linear(in_features, num_classes)

model = model.to(device)

# -------------------------
# LOSS + OPTIMIZER
# -------------------------

criterion = nn.CrossEntropyLoss()
optimizer = optim.Adam(model.parameters(), lr=learning_rate)

# -------------------------
# TRAINING LOOP
# -------------------------

for epoch in range(epochs):

    model.train()
    running_loss = 0

    for images, labels in tqdm(train_loader):

        images = images.to(device)
        labels = labels.to(device)

        outputs = model(images)
        loss = criterion(outputs, labels)

        optimizer.zero_grad()
        loss.backward()
        optimizer.step()

        running_loss += loss.item()

    train_loss = running_loss / len(train_loader)

    # -------------------------
    # VALIDATION
    # -------------------------

    model.eval()
    correct = 0
    total = 0

    with torch.no_grad():

        for images, labels in val_loader:

            images = images.to(device)
            labels = labels.to(device)

            outputs = model(images)
            _, predicted = torch.max(outputs, 1)

            total += labels.size(0)
            correct += (predicted == labels).sum().item()

    accuracy = 100 * correct / total

    print(f"\nEpoch {epoch+1}/{epochs}")
    print(f"Train Loss: {train_loss:.4f}")
    print(f"Validation Accuracy: {accuracy:.2f}%")

# -------------------------
# SAVE MODEL + CLASSES
# -------------------------

torch.save({
    "model_state": model.state_dict(),
    "classes": train_dataset.classes
}, "banana_ripeness_model.pth")

print("Model saved with class labels.")

