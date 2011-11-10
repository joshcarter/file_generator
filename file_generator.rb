#!/usr/bin/env ruby

require 'fileutils'
require './test_tree'
require 'optparse'

srand 0

options = {}
options[:depth]   ||= 0
options[:breadth] ||= 1
options[:file_size] ||= "100k"

option_parser = OptionParser.new do |opts|
  opts.on("-d DIR", "--directory DIR", "Directory to place test files in") do |param|
    options[:directory] = param
  end

  opts.on("-s SIZE", "--size SIZE", "Total size of test files") do |param|
    options[:size] = param
  end

  opts.on("-f FILE_SIZE", "--filesize FILE_SIZE", "Size of individual files") do |param|
    options[:file_size] = param
  end

  opts.on("--depth DEPTH", "Depth of directory heirachry") do |param|
    options[:depth] = param.to_i
  end

  opts.on("--breadth BREADTH", "Breadth of each directory") do |param|
    options[:breadth] = param.to_i
  end
end

option_parser.parse!

raise OptionParser::MissingArgument.new("Must specify destination directory") unless options[:directory]
raise OptionParser::MissingArgument.new("Must specify tree size, e.g. --size 1g") unless options[:size]

md = options[:size].match(/(\d+)([bkmgt])/)

raise OptionParser::InvalidArgument.new("Tree size must be numeric plus scale, [xxx][bkmgt]") unless md
size, scale = md[1].to_i, md[2]

size *= case scale
  when "b", "B" then 1
  when "k", "K" then 1024
  when "m", "M" then 1024 * 1024
  when "g", "G" then 1024 * 1024 * 1024
  when "t", "T" then 1024 * 1024 * 1024 * 1024
end

md = options[:file_size].match(/(\d+)([bkmgt])/)

raise OptionParser::InvalidArgument.new("File size must be numeric plus scale, [xxx][bkmgt]") unless md
file_size, file_scale = md[1].to_i, md[2]

file_size *= case file_scale
  when "b", "B" then 1
  when "k", "K" then 1024
  when "m", "M" then 1024 * 1024
  when "g", "G" then 1024 * 1024 * 1024
  when "t", "T" then 1024 * 1024 * 1024 * 1024
end

if (file_size > size)
  raise "File size (#{file_size}) cannot be greater than total size (#{size})"
end

FileUtils.mkdir_p options[:directory]
TestTree.new options[:directory], size, options[:depth].to_i, options[:breadth].to_i, file_size, 0.5
