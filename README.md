# Stinglet Deployment Instructions

## Build and Install Stinglet and Its Dependencies

### Step 1: Clone this Repo and Set it as Working Directory

Run:

```bash
git clone https://github.com/matte21/stinglet-deploy && \
    cd stinglet-deploy
```

### Step 2: Pull the Submodules for Stinglet and its Dependencies

Run:

```bash
git submodule update --init --recursive
```

Note: the command might take a few minutes to complete.

### Step 3: Build and Install the Custom Linux Kernel

Run the following **interactive** script (when it pauses to ask you for input,
just press enter):

```bash
build-and-install/3-linux.sh
```

After the script is done, manually edit file...

Then, update the grub config and reboot:

```bash
sudo update-grub && sudo reboot
```

Upon rebooting, the new kernel should be running. To verify this, run:

```bash
uname -r
```
