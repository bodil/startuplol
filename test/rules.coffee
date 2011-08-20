assert = require "assert"
rules = require "rules"

assert.answer = (question, answer, session) ->
  req =
    session: session or {}
  res = {}
  result = rules.answer question, req, res
  assert.equal result, answer
  req.session

module.exports =

  "remember names between sessions": ->
    session1 = assert.answer "my name is alice. what is my name?", "alice"
    assert.answer "what is my name?", "alice", session1
    # Try it with two simultaneous sessions and make sure they don't affect each other
    session2 = assert.answer "my name is bob. what is my name?", "bob"
    assert.answer "what is my name?", "bob", session2
    assert.answer "what is my name?", "bob", session1

  "shopping cart": ->
    session = assert.answer "what products do you have for sale (comma separated)", "product1, product2, product3"
    assert.answer "how many dollars does one product1 cost", "1.00", session
    assert.answer "how many dollars does one product2 cost", "2.00", session
    assert.answer "how many dollars does one product3 cost", "3.00", session
    assert.answer "please put 445 product3 in my shopping cart", "okay", session
    assert.answer "please put 2 product1 in my shopping cart", "okay", session
    assert.answer "what is my order total", "1337.00", session

  "trivia": ->
    assert.answer "what currency did Spain use before the Euro", "peseta"
    assert.answer "what colour is a banana", "yellow"
    assert.answer "who is the Prime Minister of Great Britain", "David Cameron"
    assert.answer "who played James Bond in the film Dr No", "Sean Connery"
    assert.answer "what is the twitter id of the organizer of this dojo", "jhannes"
    assert.answer "which city is the Eiffel tower in", "Paris"

  # Math
  "a plus b": ->
    assert.answer "what is 11 plus 12", "23"
  "a minus b": ->
    assert.answer "what is 3682 minus 2345", "1337"
  "a multiplied by b": ->
    assert.answer "what is 16 multiplied by 8", "128"
  "a divided by b with integer result": ->
    assert.answer "what is 32 divided by 2", "16"
  "a divided by b with floating point result": ->
    assert.answer "what is 32 divided by 3", "10.666666666666666"
  "a plus b multiplied by c": ->
    assert.answer "what is 3 plus 5 multiplied by 8", "43"
  "a multiplied by b plus c": ->
    assert.answer "what is 3 multiplied by 8 plus 5", "29"
  "find the largest number": ->
    assert.answer "which of the following numbers is the largest: 16, 31337, 1337, 23", "31337"
  "find primes": ->
    assert.answer "which of the following numbers are primes: 1, 2, 3, 4, 5, 6, 7, 8, 9, 1337, 1327", "1, 2, 3, 5, 7, 1327"
  "find fibonacci numbers": ->
    assert.answer "what is the 0th number in the Fibonacci sequence", "0"
    assert.answer "what is the 1st number in the Fibonacci sequence", "1"
    assert.answer "what is the 2nd number in the Fibonacci sequence", "1"
    assert.answer "what is the 3rd number in the Fibonacci sequence", "2"
    assert.answer "what is the 4th number in the Fibonacci sequence", "3"
    assert.answer "what is the 11th number in the Fibonacci sequence", "89"
    assert.answer "what is the 40th number in the Fibonacci sequence", "102334155"
  "find squares and cubes": ->
    assert.answer "which of the following numbers is both a square and a cube: 1, 5, 729, 1337, 4096, 16384, 262144", "1, 729, 4096, 262144"

