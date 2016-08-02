CIS Settings
========

## CIS settings for Mac (~~10.9~~, 10.10, and 10.11)

This is an attempt at checking off the list for auditing and remediating CIS Level 1 settings on an OS X installation. Some Level 2 sections are implemented as well, as they make sense in the two environments this has been used in. All Level 2 Scored coming soon. For now, the script defaults to Level 1. 

There are some elements of Level 2 that I consider to be important. These elements have been deemed Level 1.5 by me. You can now select `[-l|--level] [1, 1.5, 2]` when running the script. Defaults to Level 1.
- Level 1 attempts to include all Scored recommendations from the benchmark
- Level 1.5 includes all from Level 1, plus additional considerations from Level 2.
- Level 2 includes all from Level 1, plus attempts to include all Scored Level 2 recommendations.

**Use at your own risk, please. There may be dragons.** Certain aspects of this script can completely hose a perfectly good system. **Test in your own environment on non-production equipment!**

- 10.9 Mavericks file is mostly here just for posterity. Based off 1.0 benchmarks. *Please don't use.*
- 10.10 Yosemite is based off 1.2.0 benchmarks.
- 10.11 El Capitan is based off 1.1.0 benchmarks.

The benchmarks are available at the [Center for Internet Security] (https://benchmarks.cisecurity.org/)

### Usage

To use this script on an already online and available system, download the appropriate `benchmark.sh` file and then `chmod +x` then run it `./benchmark.sh [-l|--level] [1, 1.5, 2]`

The prefered method of running this is during a first boot after imaging. This has been tested with Casper v9+.
