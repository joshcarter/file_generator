class TestFile
  BLOCK_SIZE = 256
  PATTERN_BLOCK = 'A' * BLOCK_SIZE

  def initialize(path, size, opts = {})
    opts[:randomness] ||= 0.5

    dir = File.dirname path
    name = File.basename path

    Dir.chdir(dir) do |d|
      File.open(name, "w") { |f| fill(f, size, opts) }
    end
  end

private

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
