require 'FileUtils'
require './test_file'

class TestTree
  def initialize(dir, size, depth, breadth, file_size, file_randomness)
    Dir.chdir(dir) do |path|
      if depth.zero?
        # Create files
        (size / file_size).times do
          TestFile.new(".", file_size, file_randomness)
        end
      else
        # Create directories
        breadth.times do |i|
          dir_name = sprintf "%08d", i + 1
          FileUtils.mkdir_p dir_name
          TestTree.new(dir_name, size / breadth, depth - 1, breadth, file_size, file_randomness)
        end
      end
    end
  end
end
