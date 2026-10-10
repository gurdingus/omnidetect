import torch
import torch.nn as nn
from torchvision import datasets, models, transforms
from torch.utils.data import DataLoader
import os

# ----------------------------
# CONFIGURATION
# ----------------------------
data_dir = "apple_dataset"      # Path to your apple_dataset folder
num_classes = 3                 # unripe, ripe, spoiled
batch_size = 32
num_epochs = 10
learning_rate = 1e-4
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# ----------------------------
# DATA TRANSFORMS
# ----------------------------
data_transforms = {
    "train": transforms.Compose([
        transforms.Resize((224, 224)),
        transforms.RandomHorizontalFlip(),
        transforms.RandomRotation(15),
        transforms.ToTensor(),
        transforms.Normalize([0.485, 0.456, 0.406],  # ImageNet mean
                             [0.229, 0.224, 0.225]) # ImageNet std
    ]),
    "test": transforms.Compose([
        transforms.Resize((224, 224)),
        transforms.ToTensor(),
        transforms.Normalize([0.485, 0.456, 0.406],
                             [0.229, 0.224, 0.225])
    ])
}

# ----------------------------
# DATASETS & DATALOADERS
# ----------------------------
image_datasets = {x: datasets.ImageFolder(os.path.join(data_dir, x),
                                          data_transforms[x])
                  for x in ["train", "test"]}

dataloaders = {x: DataLoader(image_datasets[x], batch_size=batch_size, shuffle=True)
               for x in ["train", "test"]}

dataset_sizes = {x: len(image_datasets[x]) for x in ["train", "test"]}

# ----------------------------
# MODEL
# ----------------------------
model = models.resnet50(pretrained=True)   # IMAGENET1K_V1 backbone
model.fc = nn.Linear(model.fc.in_features, num_classes)
model = model.to(device)

# ----------------------------
# LOSS & OPTIMIZER
# ----------------------------
criterion = nn.CrossEntropyLoss()
optimizer = torch.optim.Adam(model.parameters(), lr=learning_rate)

# ----------------------------
# TRAINING LOOP
# ----------------------------
for epoch in range(num_epochs):
    print(f"Epoch {epoch+1}/{num_epochs}")
    print("-"*20)

    # Each epoch has a training and testing phase
    for phase in ["train", "test"]:
        if phase == "train":
            model.train()
        else:
            model.eval()

        running_loss = 0.0
        running_corrects = 0

        for inputs, labels in dataloaders[phase]:
            inputs = inputs.to(device)
            labels = labels.to(device)

            optimizer.zero_grad()

            with torch.set_grad_enabled(phase == "train"):
                outputs = model(inputs)
                _, preds = torch.max(outputs, 1)
                loss = criterion(outputs, labels)

                if phase == "train":
                    loss.backward()
                    optimizer.step()

            running_loss += loss.item() * inputs.size(0)
            running_corrects += torch.sum(preds == labels.data)

        epoch_loss = running_loss / dataset_sizes[phase]
        epoch_acc = running_corrects.double() / dataset_sizes[phase]

        print(f"{phase} Loss: {epoch_loss:.4f} Acc: {epoch_acc:.4f}")

print("Training complete!")

# ----------------------------
# SAVE MODEL
# ----------------------------
torch.save(model.state_dict(), "apple_ripeness_model.pth")
print("Model saved as apple_ripeness_model.pth")
