require './tools'

class Solver

  def initialize rank
    @n, @nn = rank, rank*rank
    @n2     = @n+@n
    @desk   = []
    @n.times { @desk << [0] * @n }
    @depth = 0
    solve 0, 0
  end

  def solve r, c
    @desk[r][c] = (@depth+=1)
    return true if @depth >= @nn
    moves(r, c) { |r1, c1|
      return true if solve(r1, c1)
    }
    @desk[r][c] = 0
    @depth      -= 1
    false
  end

  @@shifts = [[-2, +1], [-1, +2], [+1, +2], [+2, +1], [+2, -1], [+1, -2], [-1, -2], [-2, -1]]

  def moves r, c
    @@shifts.each { |sr, sc|
      r1 = r + sr
      if r1 >= 0 && r1 < @n
        c1 = c + sc
        if c1 >= 0 && c1 < @n
          yield r1, c1 if @desk[r1][c1] == 0
        end
      end
    }
  end

  def to_s
    res = []
    @n.times do |row|
      res << @n.times.map { |col|
        d = @desk[row][col]
        d == 0 ? '  .' : ("%3d" % d)
      }.join('')
    end
    res.join "\n"
  end

end

if __FILE__ == $0
  timing "#{RUBY_ENGINE} #{RUBY_VERSION}", 1, 5 do
    Solver.new 7
  end
end
