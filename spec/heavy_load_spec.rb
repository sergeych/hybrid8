require 'spec_helper'
require 'h8'
require 'ostruct'
require 'hashie'

desk_gen = <<END
console.log 'started'

offsets = [[-1, 0], [0, 1], [1, 0], [0, -1]]

class DeskGenerator

  constructor: (@n, r0=0, c0=0) ->
    @desk = []
    for r in [0...@n]
      @desk.push (null for col in [0...@n])
    @retries = 0
    @step(r0, c0, @n * @n) or throw new Error("Failed to generate desk")

  step: (r, c, depth) ->
    @desk[r][c] = depth--
    console.log r, c, depth
    return true if depth == 0

    for [r1, c1] in @moves(r, c)
      return true if @step(r1, c1, depth)

    @retries++
    depth++
    @desk[r][c] = null
    false

  moves: (r, c) ->
    moves = []
    for [sr, sc] in offsets
      [r1, c1] = [r + sr, c + sc]
      if 0 <= r1 < @n && 0 <= c1 < @n && !@desk[r1][c1]
        moves.push [r1, c1]
    moves

  toString: ->
    res = []
    for r in [0...@n]
      res.push ( (if x == 0 then '  .' else pad(x, 3)) for x in @desk[r]).join('')
    res.join "\n"

pad = (n, len) ->
  len ?= 3
  res = n?.toString() || '.'
  res = ' ' + res while res.length < len
  res

timing = (name, cb) ->
  start = new Date().getTime()
  res = cb()
  console.log("\#{name}: \#{(new Date().getTime() - start) / 1000}")
  res

result = timing 'default', ->
  new DeskGenerator(6, 5, 1)

console.log result.toString()
console.log 'retries',result.retries
END

class Console
  def debug *args
    log *args
  end

  def log *args
    # puts *args.join(' ')
  end
end

describe 'heavy scripts' do
  it 'should pass desk gen test' do
    c           = H8::Context.new
    c[:console] = Console.new
    # c.eval "console.log('fine');"
    # pending
    js          = H8::Coffee.compile desk_gen
    begin
      c.eval js
    rescue
      n = 1
      js.each_line { |l|
        puts "%3d %s" % [n, l]
        n += 1
      }
      raise
    end
  end
end


