pad = (n, len) ->
  len ?= 3
  res = n.toString()
  res = ' '+res while res.length < len
  res

shifts = [[-2, +1], [-1, +2], [+1, +2], [+2, +1], [+2, -1], [+1, -2], [-1, -2], [-2, -1]]

class Solver

  constructor: (@n) ->
    @nn = @n * @n
    @n2 = @n + @n
    @desk = []
    @depth = 0
    for r in [0...@n]
      @desk.push (0 for col in [0...@n])
    @solve 0, 0

  solve: (r, c) ->
    @desk[r][c] = ++@depth
    return true if @depth >= @nn
    for [r1, c1] in @moves(r, c)
      return true if @solve(r1, c1)
    @desk[r][c] = 0
    @depth--
    false

  # Coffeescript does not support generators
  moves: (r, c) ->
    res = []
    for [sr, sc] in shifts
      r1 = r + sr
      if 0 <= r1 < @n
        c1 = c + sc
        if 0 <= c1 < @n && @desk[r1][c1]==0
          res.push [r1, c1]
    res

  toString: ->
    res = []
    for r in [0...@n]
      res.push ( (if x==0 then '  .' else pad(x,3)) for x in @desk[r]).join('')
    res.join "\n"

timing = (name, cb) ->
  start = new Date().getTime()
  res = cb()
  console.log("#{name}: #{(new Date().getTime() - start)/1000}")
  res

#result = timing 'KN h8', ->
# new Solver(7, 3).toString()
#console.log result



return (n, left) ->
  new Solver(n, left).toString()

