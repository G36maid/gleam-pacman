#!/usr/bin/env bash
set -e

echo "Building game..."
gleam build

echo "Copying index.html..."
cp index.html build/dev/javascript/pacman/

echo "Starting development server on http://localhost:1234/pacman/"
echo "Press Ctrl+C to stop"
echo ""

if command -v python3 &>/dev/null; then
	cd build/dev/javascript
	python3 -m http.server 1234
elif command -v php &>/dev/null; then
	php -S localhost:1234 -t build/dev/javascript
else
	echo "Installing live-server..."
	npx -y live-server@1.2.2 build/dev/javascript --port=1234 --open=pacman/
fi
