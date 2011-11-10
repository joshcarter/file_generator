class NormalDistribution
  def initialize(mean, sd)
    @mean = mean
    @sd = sd
    @use_last = false
  end

  # Variation that ensures returned number is positive. Will result in
  # chopped-off distribution, depending on mean/sd.
  def positive_rand
    raise "mean/sd too close to zero for positive_rand" if (@mean - @sd < 0)
    
    loop do
      x = rand
      return x if (x > 0)
    end    
  end

  # Borrowed from RubyStats gem
  # http://rubyforge.org/projects/rubystats/
  # by Bryan Donovan, MIT License
  #
  # Uses the polar form of the Box-Muller transformation which
  #	is both faster and more robust numerically than basic Box-Muller
  # transform. To speed up repeated RNG computations, two random values
  # are computed after the while loop and the second one is saved and
  # directly used if the method is called again.
  # see http://www.taygeta.com/random/gaussian.html
  # returns single normal deviate
  def rand
    if @use_last
      y1 = @last
      @use_last = false
    else
      w = 1
      until w < 1.0 do
        r1 = Kernel.rand
        r2 = Kernel.rand
        x1 = 2.0 * r1 - 1.0
        x2 = 2.0 * r2 - 1.0
        w  = x1 * x1 + x2 * x2
      end
      w = Math.sqrt((-2.0 * Math.log(w)) / w)
      y1 = x1 * w
      @last = x2 * w
      @use_last = true
    end
    
    @mean + y1 * @sd
  end
end
