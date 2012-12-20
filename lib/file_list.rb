require_relative 'normal_distribution'
require_relative 'test_file'

class FileList
  def initialize
    reset
  end

  def reset(seed = 0)
    @files = []
    srand(seed)
  end

  def populate(opts)
    num_files = opts[:num_files]
    total_size = opts[:size]
    file_size = opts[:file_size]

    unless num_files and total_size and file_size
      raise ArgumentError, "Missing size parameters"
    end

    file_sd = opts[:file_sd] || (file_size * 0.1).to_i
    size_dist = NormalDistribution.new(file_size, file_sd)
    dirs = opts[:dirs]
    seed = opts[:seed] || 0

    unless dirs
      raise ArgumentError, "Directory list not provided"
    end

    reset(seed)

    num_files.times do |i|
      dir = dirs[rand(0...dirs.length)]
      path = "#{dir}/file#{i + 1}.dat"
      mtime = opts[:time_base] ? opts[:time_base] + i : Time.now
      size = size_dist.positive_rand.to_i

      # Note, we could have some zero-length files at the very end
      # of the file list, depending on how the distribution works out.
      size = size < total_size ? size : total_size
      total_size -= size

      @files << { path: path, size: size, mtime: mtime }
    end

    self
  end

  def to_a
    @files
  end

  def create!(opts)
    @files.each do |file|
      opts[:mtime] = file[:mtime]
      TestFile.new file[:path], file[:size], opts
    end
  end
end
