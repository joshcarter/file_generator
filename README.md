# TODO

- Help when run with no options.


# Simple File Generator

This tool creates directories of files with varying size and compressibility.

## Options

* --directory <DIR>: directory to place test files in.
  
* --size <SIZE>[kmg]: total size of test files to generate, in k/m/g.

* --file_size <SIZE>[kmg]: size of each test file, in k/m/g.
  
* --depth <DEPTH>: depth of directory hierarchy to create. Set to 0 to just generate files; otherwise use this and the next option to create a tree of directories.
  
* --breadth <BREADTH>: number of directories to create within each directory. Total directories at each level is breadth ^ level.
  
## Notes

Currently this tool generates a fixed number of directories and files at each level, and each file is a fixed size. Later versions may allow distributions of directories/files with a given mean and standard deviation. Size of directory entries is not considered; that is controlled exclusively with the depth and breadth options. Files are created at the bottom level of directories only.
