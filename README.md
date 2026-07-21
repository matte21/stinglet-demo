# Stinglet Demo

TODO: Overview

## Build and Install Stinglet and Its Dependencies

### Step 1: Clone this Repo and Set it as Working Directory

Run:

```bash
git clone https://github.com/matte21/stinglet-demo && \
    cd stinglet-demo
```

### Step 2: Pull the Submodules for Stinglet and its Dependencies

Run:

```bash
git submodule update --init --recursive
```

Note: the command might take a few minutes to complete.

### Step 3: Build and Install the Custom Linux Kernel

> [!WARNING]
> This step has been tested only on Ubuntu 24.04. The high-level workflow is the same across all distributions, but the exact commands to run and their syntax might be different in different distributions.

Run the following **interactive** script (when it pauses to ask you for input,
just press enter):

```bash
build-and-install/3-linux.sh
```

The script takes from several minutes to one or two hours (depending on the number of CPUs,
the currently loaded modules, and the current kernel config of your machine), but the interactive
part is only during the first 5 minutes, so after 5 minutes you no longer need to attend to it.

After the script is done, you need to identify the name of the new kernel, and make it the default
kernel to use on reboot.

The custom kernel name includes the string `stinglet` and does NOT include the string `recovery`.
On Ubuntu 24.04, file `/boot/grub/grub.cfg` includes one line with the kernel name, so we can grep it
for `stinglet`, but there will be multiple matches and the matching line itself contains noise.
Extract only the kernel name with:

```bash
kernel_name=$(sudo grep stinglet /boot/grub/grub.cfg | grep menuentry | grep -v recovery | head -1 | sed "s/^\s*menuentry '\([^']*\)'.*/\1/")
```

Then, make the new kernel the default as:

```bash
sudo sed -i "s/^GRUB_DEFAULT=.*/GRUB_DEFAULT=\"Advanced options for Ubuntu>${kernel_name}\"/" /etc/default/grub
sudo update-grub
```

Finally, reboot:

```bash
sudo reboot
```

Upon rebooting, the new kernel should be running. To verify this, run:

```bash
uname -r
```

and check that the output contains the string `stinglet-fg-cgroups`. For example, on a successful
installation we'd see:

```bash
uname -r
6.6.0-stinglet-fg-cgroups+
```

### Step 4: Build and Install CRI-O and crun

Run:

```bash
sudo build-and-install/4-crio-and-crun.sh
```

It will take a few minutes to run. When done, verify that our custom cri-o and crun have been installed.

To do that, begin by checking that the binaries at the default paths are the ones in our submodules;
you can compare the binaries' md5s to make sure they are identical:

CRI-O:

```bash
md5sum components/cri-o/bin/crio /usr/bin/crio /usr/local/bin/crio
```

crun:

```bash
md5sum components/crun/crun /usr/libexec/crio/crun
```

If they are identical, you're good, otherwise, there's a bug.

Then, check that the binaries in our submodules have been built from the submodules' pinned commits.

```bash
git submodule status components/crun components/cri-o
```

Neither line may start with a `+` (a `+` means the checkout has drifted from the pinned commit).

If no line starts with a `+` the installation was successful, otherwise, there's a bug.

### Step 5: Build and Install Stinglet

Run:

```bash
build-and-install/5-stinglet.sh
```

## Run Stinglet

Run:

```bash
./run.sh
```

On success, the output should be:

```text
// some other prints...

CRI-O up and running.

// some other prints...

Stinglet up and running.
Success!
```

Once done with the experiments, you can stop Stinglet (and CRI-O):

```bash
./stop.sh
```

Note that the script deletes all currently running pods and waits for them to have been deleted.
