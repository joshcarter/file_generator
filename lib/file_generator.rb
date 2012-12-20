#!/usr/bin/env ruby

require 'fileutils'
require 'optparse'
require 'yaml'

require_relative 'directory_list'
require_relative 'file_list'

options = {}

option_parser = OptionParser.new do |opts|
  opts.on("-d DIR", "--directory DIR", "Directory to place test files in") do |param|
    options[:directory] = param
  end

  opts.on("-s SIZE", "--size SIZE", "Total size of test files") do |param|
    options[:size] = param
  end

  opts.on("-f FILE_SIZE", "--filesize FILE_SIZE", "Average size of individual files") do |param|
    options[:file_size] = param
  end

  opts.on("-n NUM_FILES", "--files NUM_FILES", "Number of individual files") do |param|
    options[:num_files] = param.to_i
  end

  opts.on("--depth DEPTH", "Maximum depth of directory heirachry") do |param|
    options[:depth] = param.to_i
  end

  opts.on("--dirs NUM_DIRS", "Total number of directories") do |param|
    options[:num_dirs] = param.to_i
  end

  opts.on("--seed SEED", "Random seed") do |param|
    options[:seed] = param.to_i
  end
end

option_parser.parse!

# TODO: merge in saved options here

# Defaults
options[:depth] ||= 1
options[:seed] ||= 0
options[:num_dirs] ||= 10

#
# Validate options
#
unless options.has_key? :directory
  raise OptionParser::MissingArgument, "Must specify destination directory (-d)"
end

if options.has_key?(:num_files) and options.has_key?(:file_size) and options.has_key(:size)
  raise OptionParser::MissingArgument, "Must specify two of: number of files (--files), avg size (--filesize), and total size (--size)"
end

[:size, :file_size].each do |opt|
  next unless options.has_key?(opt)

  md = options[opt].match(/(\d+)([bkmgt])/)

  unless md
    raise OptionParser::InvalidArgument, "Sizes must be numeric plus scale, [xxx][bkmgt]"
  end

  size, scale = md[1].to_i, md[2]

  size *= case scale
    when "b", "B" then 1
    when "k", "K" then 1024
    when "m", "M" then 1024 * 1024
    when "g", "G" then 1024 * 1024 * 1024
    when "t", "T" then 1024 * 1024 * 1024 * 1024
  end

  options[opt] = size
end

#
# User specifies two of: 1) total output size, 2) avg file size,
# 3) number of files. Given two, compute the third.
#
if options.has_key?(:size) and options.has_key?(:num_files)
  options[:file_size] = options[:size] / options[:num_files]
elsif options.has_key?(:size) and options.has_key?(:file_size)
  options[:num_files] = options[:size] / options[:file_size]
elsif options.has_key?(:num_files) and options.has_key?(:file_size)
  options[:size] = options[:num_files] * options[:file_size]
else
  raise OptionParser::MissingArgument, "Must specify two of: number of files (--files), avg size (--filesize), and total size (--size)"
end

# Now that we know how many files there are, we can set the modtime base.
options[:time_base] ||= Time.now - options[:num_files]

FileUtils.mkdir_p options[:directory]
Dir.chdir(options[:directory]) do
  File.open(".settings.yaml", "w") { |f| f.write YAML.dump(options) }

  #
  # Build directory
  #
  dl = DirectoryList.new
  dl.populate options
  dl.create!

  options[:dirs] = dl.to_a

  #
  # Lay out files within directories
  #
  fl = FileList.new
  fl.populate options
  fl.create! options
end
