require 'fileutils'

class DirectoryList
  def initialize
    reset
  end

  def reset(seed = 0)
    @tree = {}
    @dirs = [ '.' ]
    @counter = 0
    srand(seed)
  end

  def populate(opts)
    dirs = opts[:num_dirs]
    depth = opts[:depth]
    seed = opts[:seed] || 0

    if dirs.nil?
      raise ArgumentError, "must specify :num_dirs option"
    end

    if depth.nil?
      raise ArgumentError, "must specify :depth option"
    end

    reset(seed)

    if (dirs == 0) or (depth == 0)
      # Don't create any tree
      return
    end

    loop do
      path = '.'
      current = @tree

      rand(1..depth).times do |level|
        subdir = nil
        if current.empty? or (rand > 0.5)
          # Create a new directory at this level
          subdir = next_dir_name
          # puts "creating #{subdir}"

          # Add to flat list of all subdirectories in tree
          path += "/#{subdir}"
          @dirs << path

          # Add to tree representation and navigate down
          current[subdir] = {}

          # Return once we've consumed all directories
          dirs -= 1
          return(self) if (dirs == 0)
        else
          # Traverse to one of the existing directories
          subdir = current.keys[rand(0...current.keys.length)]
          # puts "descending into #{subdir}"
        end

        current = current[subdir]
      end
    end
  end

  # Create directories under current working directory
  def create!
    @dirs.each do |dir|
      FileUtils.mkdir_p(dir)
    end
  end

  def to_a
    @dirs
  end

  private

  def next_dir_name
    @counter += 1
    "dir#{@counter}"
  end
end
