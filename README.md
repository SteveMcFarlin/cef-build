# Semi-automatic and reproducible CEF build

List of chromium builds.
https://chromium.googlesource.com/chromium/src/+refs

CEF docs containing the branch numbers for Chromium builds.
https://bitbucket.org/chromiumembedded/cef/wiki/BranchesAndBuilding.md

## Initial container setup

This container will have the basic build dependencies installed. Update the `ENV CHROMIUM_VERSION` in the container file.
e.g. `ENV CHROMIUM_VERSION=117.0.5938.55`

```bash
docker build --output type=docker -t cef-buildbox:v1 -f Containerfile .
```

## Get the code (lots of it)

To get the code or update the checkout. In this example the code will be stored in `cef-build`. You need around 30GB of free disk space. Update the branch number to match the CEF version you want to build in the automate-git.py call. Search for `parser.add_option` in the `/cef/automate-git.py` file for options. Recommended build options are listed on the [Master Build](https://bitbucket.org/chromiumembedded/cef/wiki/MasterBuildQuickStart.md) page. Note only x86 is supported, and chrome for aarch is a cross compilation.

```bash
docker run --name cef-build -ti cef-buildbox:v1 /bin/bash

python3 /cef/automate-git.py --download-dir=$PWD/cef-build --branch=5938 --no-distrib --no-build

```

## Compile the things

This will bake a release build in `cef-build/chromium/src/cef/binary_distrib`. GN flags can be tweaked in the compile-cef script and additional `automate-git.py` CLI options can be passed through the command-line.

With the arm64 build you may need to run this. Check first for `./cef-build/chromium/src/build/linux/debian_bullseye_arm64-sysroot`.

```bash
python3 ./cef-build/chromium/src/build/linux/sysroot_scripts/install-sysroot.py --arch=arm64
```
You may also need to `export GYP_DEFINES=target_arch=arm64`

Compile

```bash
(docker exec -ti cef-build /bin/bash)
python3 ./compile-cef.sh --download-dir=$PWD/cef-build --branch=5938 --no-debug-build [--x64-build | --arm64-build]
```


The branch number doesn't need to match with the previous `automate-git.py` call. The compile-cef call will also ensure the given branch number has been fetched. You can refer to the [CEF branches](https://bitbucket.org/chromiumembedded/cef/wiki/BranchesAndBuilding.md) Wiki page when updating it.



## Gen the SHA files

Run `gen-sha1.sh` in the root of the container

```bash
for f in $(find cef-build/chromium/src/cef/binary_distrib -name "*.tar.bz2")
do
    echo $f
    sha1sum $f | cut -d' ' -f1 > $f.sha1
done
```

## Deploy the stuff

Copy the tarballs and checksums to cloud storage.

## Update the gstcefsrc build
Update the `CEF_DOWNLOAD_URL` and `CEF_VERSION` in your gstcefsrc build script.

# Optimized build and patching

In order to create an optimized build a build.patch file is required. To do this you can do an normal automate-git.py run with no build (checkout), modify the BUILD.gn file in chromium, and create a patch.

Run automate-git.py as normal
```bash
python3 /cef/automate-git.py --download-dir=$PWD/cef-build --branch=5563 --no-distrib --no-build --x64-build
```

After this is complete modify the build.patch file in `/cef-build/chromium/src/cef/patches/build.patch`. Now export these

```bash
export GN_DEFINES="chrome_pgo_phase=0 ffmpeg_branding=Chrome proprietary_codecs=true is_official_build=true use_sysroot=true use_allocator=none symbol_level=1 is_cfi=false use_thin_lto=false use_ozone=true"
export CEF_ARCHIVE_FORMAT="tar.bz2"
```

Compile

```bash
python3 /cef/automate-git.py --download-dir=$PWD/cef-build --branch=5563 --no-distrib --x64-build --no-cef-update --no-debug-build --force-build --build-target=cefsimple
```

If you are adding other chromium patches then please refer to README in the `cef/patch` directory. To force a clean run

```bash
python3 /cef/automate-git.py --download-dir=$PWD/cef-build --branch=5563 --no-distrib --no-build --force-clean
```

### Notes for a possible automated arch specific build

Using these scripts the only way to get an optimized BUILD.gn file would be to run the above compile step and stop it after ninja starts to run. Then modify the BUILD.gn file and run 

```
python3 ./compile-cef --download-dir=$PWD/cef-build --branch=5563 --no-debug-build --x64-build --no-chromium-update
```

The reason for this is the compile setup updates chromium (git checkout), and applies the patches. At this point I have not found another way to automate this properly. Refer to the [automate-git.py](https://bitbucket.org/chromiumembedded/cef/raw/master/tools/automate/automate-git.py) file that is downloaded into the container. The only automated way I see to do this is to build a script based off the [Master Build](https://bitbucket.org/chromiumembedded/cef/wiki/MasterBuildQuickStart.md) page.

The other alternative is to add/modify a patch to the build. take a look at /cef-build/chromium/src/cef/patch/patches/build.patch

In the cef/tools directory gclient_hook.py is what initiatiates the patching. Search for `Patching build configuration and source files for CEF`. Patcher.py does the work.

Also take a look at https://support.google.com/webdesigner/answer/10043691?hl=en, and https://bitbucket.org/chromiumembedded/cef/src/master/patch/README.txt
