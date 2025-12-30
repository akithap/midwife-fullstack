#!/bin/bash

# 1. Download Flutter SDK (if not already cached)
if [ ! -d "flutter_sdk" ]; then
    echo "Downloading Flutter SDK..."
    git clone https://github.com/flutter/flutter.git -b stable --depth 1 flutter_sdk
else
    echo "Using cached Flutter SDK..."
fi

# 2. Add Flutter to PATH
export PATH="$PATH:`pwd`/flutter_sdk/bin"

# 3. Print Version (to confirm it worked)
echo "Flutter Version:"
flutter --version

# 4. Enable Web
flutter config --enable-web

# 5. Build!
echo "Building Web App..."
flutter build web --release

echo "Build Complete!"
