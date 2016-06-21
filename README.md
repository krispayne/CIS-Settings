CIS Settings
========

## CIS settings for Mac (10.9, 10.10, and 10.11)

This is an attempt at checking off the list for auditing and remediating CIS Level 1 settings on an OS X installation via `bash`

Several lines do not work and have been commented out. Certain one's will hose a system. Left in the script for reference.

**Use at your own risk, please. There may be dragons.**

-10.9 Mavericks file is mostly here just for posterity. **Do not use it.** Based off 1.0 benchmarks

-10.10 Yosemite is based off 1.2.0 benchmarks. [CHANGELOG] (https://github.com/krispayne/CIS-Settings/commit/e773ac921c75a4b2a656be1dff80e0a0cabcc111#commitcomment-17942167)

-10.11 El Capitan is based off 1.1.0 benchmarks.

The benchmarks are available at the [Center for Internet Security] (https://benchmarks.cisecurity.org/)

### Usage

To use this script on an already online and available system, download the appropriate `benchmark.sh` file and then `chmod +x` then run it `./benchmark.sh`

The prefered method of running this is during a first boot after imaging. This has been tested with Casper v9+.
