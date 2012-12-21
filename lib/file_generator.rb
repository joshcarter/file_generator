#!/usr/bin/env ruby

require 'fileutils'
require 'optparse'
require 'yaml'

require_relative 'directory_list'
require_relative 'file_list'

#
# Parse options put on the command line
#
opts = {}

option_parser = OptionParser.new do |o|
  o.on("-d DIR", "--directory DIR", "Directory to place test files in") do |param|
    opts[:directory] = param
  end

  o.on("-s SIZE", "--size SIZE", "Total size of test files") do |param|
    opts[:size] = param
  end

  o.on("-f FILE_SIZE", "--filesize FILE_SIZE", "Average size of individual files") do |param|
    opts[:file_size] = param
  end

  o.on("-n NUM_FILES", "--files NUM_FILES", "Number of individual files") do |param|
    opts[:num_files] = param.to_i
  end

  o.on("--depth DEPTH", "Maximum depth of directory heirachry") do |param|
    opts[:depth] = param.to_i
  end

  o.on("--dirs NUM_DIRS", "Total number of directories") do |param|
    opts[:num_dirs] = param.to_i
  end

  o.on("--seed SEED", "Random seed") do |param|
    opts[:seed] = param.to_i
  end
  
  o.on("-h", "--help", "Help") do
    puts o
    exit
  end
end

begin
  option_parser.parse!

  #
  # Option defaults.
  #
  opts[:depth] ||= 1
  opts[:seed] ||= 0
  opts[:num_dirs] ||= 10

  #
  # Validate opts
  #
  unless opts.has_key? :directory
    raise OptionParser::MissingArgument, "Must specify destination directory (-d)"
  end

  # NOTE: all 3 will be true when we're loading an external settings file
  # if opts.has_key?(:num_files) and opts.has_key?(:file_size) and opts.has_key?(:size)
  #   raise OptionParser::MissingArgument, "Must specify two of: number of files (--files), avg size (--filesize), and total size (--size)"
  # end

  [:size, :file_size].each do |opt|
    next unless opts.has_key?(opt)
    next unless opts[opt].is_a? String

    md = opts[opt].match(/(\d+)([bkmgt])/)

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

    opts[opt] = size
  end

  #
  # User specifies two of: 1) total output size, 2) avg file size,
  # 3) number of files. Given two, compute the third.
  #
  if opts.has_key?(:size) and opts.has_key?(:num_files)
    opts[:file_size] = opts[:size] / opts[:num_files]
  elsif opts.has_key?(:size) and opts.has_key?(:file_size)
    opts[:num_files] = opts[:size] / opts[:file_size]
  elsif opts.has_key?(:num_files) and opts.has_key?(:file_size)
    opts[:size] = opts[:num_files] * opts[:file_size]
  else
    raise OptionParser::MissingArgument, "Must specify two of: number of files (--files), avg size (--filesize), and total size (--size)"
  end

  # Now that we know how many files there are, we can set the modtime base.
  opts[:time_base] ||= Time.now - opts[:num_files]
rescue OptionParser::ParseError => e
  puts "Error: #{e}"
  puts
  puts option_parser
  exit -1
end

FileUtils.mkdir_p opts[:directory]
Dir.chdir(opts[:directory]) do
  #
  # Build directory
  #
  dl = DirectoryList.new
  dl.populate opts
  dl.create!

  opts[:dirs] = dl.to_a

  #
  # Lay out files within directories
  #
  fl = FileList.new
  fl.populate opts
  fl.create! opts
end
