# File Generator

This tool creates files and directories with varying size and compressibility. Run `bin/file_generator` with the options below.

## Options

Always required:

* `--directory DIR`: directory to place test files in. It will be created if it doesn't exist.

You must specify *two* of the following, and the third factor will be calculated from the other two:
  
* `--size SIZE[kmgt]`: total size of test files to generate, with k/m/g suffix.

* `--file_size SIZE[kmg]`: average size of each test file, in k/m/g. Individual file sizes will differ (chosen from a normal distribution) but the sum of their sizes will exactly equal what you specified for --size.

* `--files NUM_FILES`: total number of files to create.

These options control creation of directories:

* `--dirs DIRS`: number of directories to create. Set to zero to disable creation of directories.

* `--depth DEPTH`: maximum depth of directory hierarchy to create. Exact depth will vary from 0..DEPTH, with files scattered across all directories at all depths.

Additional options:

* `--seed SEED`: random seed, zero by default.

## File Generation

Test files will vary in size and their contents are a mix of pattern data and random data. The balance is currently fixed at 50% pattern/random.

**Performance Note:** for best performance, build the C-based random block generator:

    cd ext
    ruby extconf.rb
    make

This will improve file generation speed by a factor of 50. Neither the Ruby nor C-based generator use cryptographic strength random number generator. It's enough to defeat compression, however. Zip a directory of test files to verify, they should compress by 49%-51%.

## Restarting the Generator

If `file_generator` is run with the same options repeatedly, it will generate the same file/directory layout. It won't regenerate files that it already wrote on a previous pass. If you need to control-c the tool, just run it again and it'll pick up where it left off.

## License

`file_generator` is copyright 2012 by Spectra Logic. It may be redistributed under the same terms as Ruby 1.9.
