questions = []

exports.question = (re, func) ->
  questions.push
    re: re
    func: func

render = (answer) ->
  if typeof answer == "object" then (answer.join ", ") else answer

exports.answer = (q, req, res) ->
  context =
    req: req
    res: res
  for i in questions
    m = q.match i.re
    return render i.func.apply context, [m] if m
  "Bruce Schneier" # Default answer, ref. http://www.schneierfacts.com/fact/1

# Unbreak Javascript
cons = exports.cons = (item, list) -> [item].concat list

# Takes a match result, converts all matched groups to ints and returns them as a list
ints = (m) -> ((parseInt x, 10) for x in m.slice 1)

# Takes a match result, assumes the first group is a comma separated list of ints, parses and returns a list
exports.intlist = (m) -> ints cons null, (x.trim() for x in m[1].split ",")

# Wraps a function to take ints as arguments
exports.ints = (func) -> (m) -> func.apply this, ints m

# Wraps a function to take intlist as arguments
exports.intlist = (func) -> (m) -> func.apply this, intlist m

# Wraps a function to take matched groups as arguments
exports.strings = (func) -> (m) -> func.apply this, m.slice 1
