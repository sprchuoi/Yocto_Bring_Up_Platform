# Git Setup Commands

## After creating your repository on GitHub/GitLab/etc., run these commands:

```bash
# Add your remote repository (replace with your actual repository URL)
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git

# Or if using SSH:
# git remote add origin git@github.com:YOUR_USERNAME/YOUR_REPO_NAME.git

# Push the code to your repository
git push -u origin master

# Or if your default branch is 'main':
# git branch -M main
# git push -u origin main
```

## To clone this repository on another machine:

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
cd YOUR_REPO_NAME

# Initialize and update submodules
git submodule update --init --recursive

# Set up the build environment
./setup-build.sh

# Or manually:
source poky/oe-init-build-env build-beaglebone

# Restore configuration files
./restore-config.sh

# Start building
bitbake core-image-minimal
```