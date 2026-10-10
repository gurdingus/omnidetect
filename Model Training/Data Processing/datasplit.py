import os
import shutil
import random

source_dir = "BananaImageBD"
target_dir = "dataset"

train_ratio = 0.8

for class_name in os.listdir(source_dir):

    class_path = os.path.join(source_dir, class_name)

    if not os.path.isdir(class_path):
        continue

    images = os.listdir(class_path)
    random.shuffle(images)

    split_index = int(len(images) * train_ratio)

    train_images = images[:split_index]
    val_images = images[split_index:]

    # create folders
    os.makedirs(f"{target_dir}/train/{class_name}", exist_ok=True)
    os.makedirs(f"{target_dir}/val/{class_name}", exist_ok=True)

    # copy training images
    for img in train_images:
        shutil.copy(
            os.path.join(class_path, img),
            os.path.join(f"{target_dir}/train/{class_name}", img)
        )

    # copy validation images
    for img in val_images:
        shutil.copy(
            os.path.join(class_path, img),
            os.path.join(f"{target_dir}/val/{class_name}", img)
        )

print("Dataset split complete.")

