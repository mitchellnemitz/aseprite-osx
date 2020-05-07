# Aseprite OSX

Simple build script to build Aseprite.app

### Running

```bash
# Install compilation tools
xcode-select --install

# Clone this project
git clone git@github.com:mitchellnemitz/aseprite-osx.git
cd aseprite-osx

# Optionally, clean previous build
./clean.sh

# Build Aseprite.app
./build.sh

# Install to /Applications/Aseprite.app
./install.sh
```
