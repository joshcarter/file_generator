class TestFile
  BLOCK_SIZE = 65536
  PATTERN_BLOCK = 'A' * BLOCK_SIZE
  @@randseq_warning = true
  @@logs = []

  def initialize(path, size, opts = {})
    opts[:randomness] ||= 0.5

    dir = File.dirname path
    name = File.basename path
    start_time = Time.now

    Dir.chdir(dir) do |d|
      File.open(name, "w") { |f| fill(f, size, opts) }
      log(path, size, start_time, Time.now)
      
      if opts[:mtime]
        File.utime(opts[:mtime], opts[:mtime], name)
      end        
    end
  end

private

  def log(path, size, start_time, end_time)
    # Track recent files created
    @@logs << [size, end_time - start_time]

    if @@logs.length > 1000
      @@logs.slice! 0, @@logs.length - 1000
    end

    total_bytes, total_time = @@logs.reduce([0, 0]) do |acc, i|
      [acc[0] + i[0], acc[1] + i[1]]
    end
    
    # Let system get going for a few seconds before logging bandwidth.
    if total_time > 5.0
      scales = ['B/s', 'KiB/s', 'MiB/s', 'GiB/s']
      bandwidth = total_bytes.to_f / total_time
    
      while (bandwidth > 1000 && scales.length > 1)
        bandwidth /= 1024
        scales.shift
      end
    
      STDOUT.puts sprintf("Created %-50s (%0.1f %s)", path, bandwidth, scales.first)
    else
      STDOUT.puts sprintf("Created %-50s", path)
    end
  end

  def fill(f, size, opts)
    begin
      # Use C-based random sequence generator if it's available.
      require_relative '../ext/randseq'

      byteseq = RandSeq::Bytes.new(BLOCK_SIZE, opts[:seed])

      pattern_block =    -> f { f.write PATTERN_BLOCK }
      random_block =     -> f { f.write byteseq.next }
      pattern_leftover = -> f, n { f.write PATTERN_BLOCK[0...n] }
      random_leftover =  -> f, n { f.write byteseq.next[0...n] }
    rescue LoadError
      # Fall back to pure-Ruby generator
      if @@randseq_warning
        STDERR.puts "INFO: Using pre-ruby random generator; recommend using ext/randseq!"
        STDERR.puts "INFO: cd ext; ruby extconf.rb; make"
        @@randseq_warning = false
      end
      
      pattern_block =    -> f { f.write PATTERN_BLOCK }
      random_block =     -> f { BLOCK_SIZE.times { f.write((rand 256).chr) } }
      pattern_leftover = -> f, n { f.write PATTERN_BLOCK[0...n] }
      random_leftover =  -> f, n { n.times { f.write((rand 256).chr) } }
    end

    blocks = (size / BLOCK_SIZE)
    leftover = (size % BLOCK_SIZE)
    random_blocks = (blocks * opts[:randomness]).to_i
    pattern_blocks = blocks - random_blocks

    blocks.times do
      if random_blocks.zero?
        pattern_block.call(f)
        pattern_blocks -= 1
      elsif pattern_blocks.zero?
        random_block.call(f)
        random_blocks -= 1
      elsif rand(nil) > 0.5
        pattern_block.call(f)
        pattern_blocks -= 1
      else
        random_block.call(f)
        random_blocks -= 1
      end
    end

    # Fill in leftover
    if leftover == 0
      # Don't need to do anything
    elsif opts[:randomness] > 0.5
      random_leftover.call(f, leftover)
    else
      pattern_leftover.call(f, leftover)
    end
  end
end
