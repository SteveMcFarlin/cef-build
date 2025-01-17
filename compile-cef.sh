#!/usr/bin/env python3

import os
import sys

def main(*args):
    sys.argv.extend(['--force-clean', '--build-target=cefsimple'])

    # FIXME: Allow easier tuning of this stuff.
    os.environ['GN_DEFINES'] = "chrome_pgo_phase=0 ffmpeg_branding=Chrome proprietary_codecs=true is_official_build=true use_sysroot=true use_allocator=none symbol_level=1 is_cfi=false use_thin_lto=false use_ozone=true"
    os.environ['CEF_ARCHIVE_FORMAT'] = 'tar.bz2'

    if '--arm64-build' in args:
        os.environ['CEF_INSTALL_SYSROOT'] = 'arm64'

    import runpy
    runpy.run_path('/cef/automate-git.py', run_name="__main__")
    return 0

if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
