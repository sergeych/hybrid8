errorsCount = 0

class TestFailed extends Error

fail = (msg) ->
  msg = "Failed: #{msg}\n"
  errorsCount++
  try
    throw Error()
  catch e
    msg += e.stack.split("\n")[3]+' '+__FILE__
    console.error msg

ok = (condition, message='') ->
  condition or fail "condition is not true"

gt = (a, b, message = '') ->
  unless a > b
    fail "#{a} > #{b} #{message}"

ge = (a, b, message = '') ->
  unless a >= b
    fail "#{a} >= #{b} #{message}"

lt = (a, b, message = '') ->
  unless a < b
    fail "#{a} < #{b} #{message}"

le = (a, b, message = '') ->
  unless a <= b
    fail "#{a} <= #{b} #{message}"

eq = (a, b, message = '') ->
  unless a == b
    fail "#{a} == #{b} #{message}"

ne = (a, b, message = '') ->
  unless a != b
    fail "#{a} != #{b} #{message}"


ok File.dirname(__FILE__).match(/spec\/coffee$/)
eq File.extname(__FILE__), '.coffee'

eq File.basename(__FILE__), 'cli_tests.coffee'

if errorsCount > 0
  print "#{errorsCount} tests failed"
else
  print "All tests passed"
