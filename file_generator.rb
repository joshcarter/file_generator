#!/usr/bin/env ruby

require 'FileUtils'
require './test_tree'
require 'optparse'

srand 0

options = {}
option_parser = OptionParser.new do |opts|
  opts.on("-d DIR","--directory DIR") do |param|
    options[:directory] = param
  end

  opts.on("-s SIZE","--size SIZE") do |param|
    options[:size] = param
  end

  opts.on("-f FILE_SIZE","--filesize FILE_SIZE") do |param|
    options[:file_size] = param
  end

  opts.on("--depth DEPTH") do |param|
    options[:depth] = param.to_i
  end

  opts.on("--breadth BREADTH") do |param|
    options[:breadth] = param.to_i
  end
end

option_parser.parse!
options[:depth]   ||= 2
options[:breadth] ||= 10
options[:file_size] ||= "100k"

raise "Must specify destination directory" unless options[:directory]
raise "Must specify tree size, e.g. --size 1g" unless options[:size]

md = options[:size].match(/(\d+)([kmgt])/)

raise "Tree size must be numeric plus scale, [xxx][kmgt]" unless md
size, scale = md[1].to_i, md[2]

case scale
  when "k", "K" then size *= 1024
  when "m", "M" then size *= 1024 * 1024
  when "g", "G" then size *= 1024 * 1024 * 1024
  when "t", "T" then size *= 1024 * 1024 * 1024 * 1024
end

md = options[:file_size].match(/(\d+)([kmgt])/)

raise "File size must be numeric plus scale, [xxx][kmgt]" unless md
file_size, file_scale = md[1].to_i, md[2]

case file_scale
  when "k", "K" then file_size *= 1024
  when "m", "M" then file_size *= 1024 * 1024
  when "g", "G" then file_size *= 1024 * 1024 * 1024
  when "t", "T" then file_size *= 1024 * 1024 * 1024 * 1024
end

FileUtils.mkdir_p options[:directory]
TestTree.new options[:directory], size, options[:depth].to_i, options[:breadth].to_i, file_size, 0.5
