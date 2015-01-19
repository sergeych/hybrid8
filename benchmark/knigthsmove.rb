require './tools'

class Solver

  def initialize rank, leave_free=0
    @n, @nn     = rank, rank*rank
    @n2         = @n+@n
    @leave_free = leave_free
    @desk       = []
    @n.times { @desk << [0] * @n }
    @depth = 0
    solve 0, 0
  end

  def solve r, c
    @desk[r][c] = (@depth+=1)
    return true if @depth == @nn-@leave_free
    moves(r, c) { |r1, c1|
      return true if solve(r1, c1)
    }
    @desk[r][c] = 0
    @depth      -= 1
    false
  end

  @@shifts = [[-2, +1], [-1, +2], [+1, +2], [+2, +1], [+2, -1], [-2, -1]]

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

cs = js_context.eval coffee(:knightsmove)

N, L = 7, 3

res1 = res2 = 0
timing('total') {
  tt = []
  tt << Thread.start { timing('ruby') { res1 = Solver.new(N, L).to_s } }
  tt << Thread.start { timing('coffee') { res2 = cs.call(N, L) } }
  tt.each &:join
}

if res1 != res2
  puts "WRONG RESULTS test data can not be trusted"
  puts "Ruby:\n#{res1}"
  puts "Coffee:\n#{res2}"
end

puts res1
