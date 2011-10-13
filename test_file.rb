class TestFile
  BLOCK_SIZE = 256
  PATTERN_BLOCK = 'A' * BLOCK_SIZE
  
  def initialize(dir, size, randomness = 0.5)
    Dir.chdir(dir) do |path|
      # Sequentially number files
      file_name = sprintf "%08d.tst", (Dir["*.tst"].length + 1)
    
      File.open(file_name, "w") { |f| fill(f, size, randomness) }
    end
  end

private

  def pattern_block(f)
    f.write PATTERN_BLOCK
  end
  
  def random_block(f)
    BLOCK_SIZE.times { f.write (rand 256).chr }
  end

  def fill(f, size, randomness)
    blocks = (size / BLOCK_SIZE)
    random_blocks = (blocks * randomness).to_i
    pattern_blocks = blocks - random_blocks
    
    puts "randomness = #{randomness}, rand blocks #{random_blocks}, pattern blocks #{pattern_blocks}"
    
    blocks.times do
      if random_blocks.zero?
        pattern_block(f)
        pattern_blocks -= 1
      elsif pattern_blocks.zero?
        random_block(f)
        random_blocks -= 1
      elsif rand(nil) > 0.5
        pattern_block(f)
        pattern_blocks -= 1
      else
        random_block(f)
        random_blocks -= 1
      end
    end
  end
end
