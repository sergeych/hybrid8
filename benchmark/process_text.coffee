return (text) ->
  words = {}
  freq = []
  for w in text.split(/\s+/)
    w = w.toLowerCase()
    continue if w == 'which' || w == 'from' || w.length < 4
    w = w[2..-1]
    unless (rec = words[w])?.count++
      freq.push (words[w] = { word: w, count: 1})
  freq.sort (a,b) ->
    b.count - a.count
  freq[0..10]
