# nerves_system_x86_64_kiosk

Custom Nerves system for the **Higole F9B Pro (Intel N95 / Alder Lake-N)** kiosk.
Forked from [`nerves_system_x86_64`](https://github.com/nerves-project/nerves_system_x86_64)
**v1.33.5** (OTP 28 / Linux 6.12). Every change is driven by `results/probe-report.txt`
and summarized in `results/go-no-go.md`.

## Why a fork is needed
The stock generic system is virtio/QEMU-focused: it ships `DRM_VIRTIO_GPU` + `VIRTIO_NET`
only, with **no** i915, r8169, DesignWare-I2C/Goodix, or MIPI-DSI. None of the F9B's real
silicon would work on the stock image. This fork adds it.

## Changes vs. upstream
| File | Change |
|------|--------|
| `linux-6.12.defconfig` | + `DRM_I915` (incl. Intel DSI encoder, driven by VBT), fbdev+fbcon+rotation; + `I2C_DESIGNWARE_*` + `TOUCHSCREEN_GOODIX`; + `R8169` (+ realtek PHY) for RTL8125; + `SATA_AHCI` for the internal SSD; + `RTW88_8821CE` (WiFi, optional). |
| `nerves_defconfig` | + `LINUX_FIRMWARE` (i915 DMC/GuC + rtl8821c); + Mesa "iris" / Wayland / libinput graphics stack; + `cage` (kiosk compositor) + `cog`/`wpewebkit` (browser). |
| `grub.cfg` | + `fbcon=rotate:1` (boot console). The panel scans out portrait (800×1280) and is mounted rotated; the real kiosk rotation is a Wayland compositor output transform. |
| `mix.exs` | renamed app to `:nerves_system_x86_64_kiosk`. |

## ⚠️ Not yet built / verified
Building this from source requires the full Buildroot host toolchain. On the current
host **flex, bison, and gperf are missing** and need `sudo apt-get` (unavailable here),
so the image has **not** been compiled or boot-tested. Two things to confirm on a
provisioned build host:

1. **Compositor/browser package names.** Buildroot *silently drops* unknown symbols
   during `olddefconfig`. Confirm `CAGE` / `COG` / `WPEWEBKIT` exist in this Buildroot
   version via `make menuconfig`; if a name differs, the browser is silently omitted.
   (Alternative stack: `weston` + `qt5webengine`.)
2. **Panel rotation direction** (`fbcon=rotate:` value and the compositor `transform`)
   and the **touch coordinate transform** — both must be tuned on the physical device.

## Build
```
# on a host with: sudo apt-get install -y flex bison gperf build-essential
./scripts/50_build_custom.sh      # deps.get + mix firmware (long, from source)
./run.sh qemu                     # boots to IEx; display/touch only testable on the F9B
```
To fall back to the fast prebuilt base, re-point `kiosk_poc/mix.exs` at
`{:nerves_system_x86_64, "~> 1.33.5", ...}`.
