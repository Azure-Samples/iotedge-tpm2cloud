# TPM2 Software Stack
Here's a typical stack required to use a TPM 2.0 device in a linux environment:

![](../images/tpm2-stack.png)

You can build the stack from source using the instructions in the [tpm2-software github repo](https://github.com/tpm2-software/tpm2-tss) or the convenience scripts in [iot-edge-1.2-tpm](https://github.com/arlotito/iot-edge-1.2-tpm/blob/main/step-by-step.md).

However, building from source is a long process and requires several additional dependancies not needed at the runtime.
A better approach would be building redistributable packages on a DEV machine, and install the packages on the target platform at manufacturing time (and afterwards, over-the-air, for maintenance).

## Build deb package
Here are some scripts to build debian packages from source.

**DISCLAIMER**: *these packages do not follow any best practice, are not tested, not maintained and should not be used in production.*

To build the stack:
```bash
cd scripts-stack
./build.sh <os-name> <version>
```

The output will be a single 'iotedge-tpm2cloud_<version>_<os-name>_<architecture>.tar.gz' archive with all the debian packages.

The output file will be stored in the '<root-project>/packages' folder

## Example
Let's run the following on a x86/amd64 machine running Ubuntu 20.04:
```bash
./build.sh ubuntu2004 4
```

The script will build all the debian packages and will archive them in the following file:
```bash
packages/iotedge-tpm2cloud_4_ubuntu2004_amd64.tar.gz
```


## Install from deb packages
To install the TPM stack from pre-built .deb packages:
```bash
# (if 'swtpm', it will install the ibmswtpm2 TPM simulator as well)
#
# examples: 
#       ./tpm2-stack-install.sh debian11_armhf hwtpm        # raspberry pi, HW TPM
#       ./tpm2-stack-install.sh ubuntu2004_amd64 hwtpm      # x86, ubuntu 20.04, HW TPM
#       ./tpm2-stack-install.sh ubuntu1804_amd64 swtpm      # x86, ubuntu 18.04, SW TPM (ibmswtpm2)
./tpm2-stack-install.sh <platform> <hw-or-sw-tpm>
```

## Sanity checks
Get a random number from the TPM:
```bash
tpm2_getrandom 4 | hexdump
```

Optionally check the services:
```bash
sudo systemctl status tpm2-abrmd.service
sudo systemctl status ibmswtpm2

dbus-send --system --dest=com.intel.tss2.Tabrmd --type=method_call --print-reply /com/intel/tss2/Tabrmd/Tcti org.freedesktop.DBus.Introspectable.Introspect
```
...and you should see:

```
method return time=1524690897.749245 sender=:1.192 -> destination=:1.193 serial=7 reply_serial=2
   string "<!DOCTYPE node PUBLIC "-//freedesktop//DTD D-BUS Object Introspection 1.0//EN"
                      "http://www.freedesktop.org/standards/dbus/1.0/introspect.dtd">
<!-- GDBus 2.50.3 -->
<node>
  <interface name="org.freedesktop.DBus.Properties">
    <method name="Get">
      <arg type="s" name="interface_name" direction="in"/>
      <arg type="s" name="property_name" direction="in"/>
      <arg type="v" name="value" direction="out"/>
      ...
```