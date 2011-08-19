# To install dependencies:
# $ npm install express mongoose connect-mongoose

fs = require "fs"
express = require 'express'
mongoose = require 'mongoose'
sessionStore = require("connect-mongoose")(express)
math = require "./math"
dispatch = require "./dispatch"
question = dispatch.question
ints = dispatch.ints
intlist = dispatch.intlist
strings = dispatch.strings


# Connect to MongoDB

mongo_uri = "mongodb://localhost/bodilpwnz"
console.log "Connecting to #{mongo_uri}"
mongoose.connect mongo_uri


# Configure the Express HTTP server

app = express.createServer()

# Configure an HTTP session handler using MongoDB to persist session state

app.use express.cookieParser()
app.use express.session
  secret: "foo"
  store: new sessionStore()


# Question rules

# Math
question /which of the following numbers is both a square and a cube: (.*)/, intlist -> (x for x in arguments when math.square_and_cube x)
question /which of the following numbers is the largest: (.*)/, intlist -> Math.max.apply this, arguments
question /which of the following numbers are primes: (.*)/, intlist -> (x for x in arguments when math.is_prime x)
question /what is (\d+) minus (\d+)/, ints (a, b) -> a - b
question /what is (\d+) multiplied by (\d+) plus (\d+)/, ints (a, b, c) -> a * b + c
question /what is (\d+) plus (\d+) multiplied by (\d+)/, ints (a, b, c) -> a + b * c
question /what is (\d+) plus (\d+)/, ints (a, b) -> a + b
question /what is (\d+) divided by (\d+)/, ints (a, b) -> a / b
question /what is (\d+) multiplied by (\d+)/, ints (a, b) -> a * b
question /what is the (\d+).* in the Fibonacci sequence/, ints (n) -> math.fibFast n

# Name
question /my name is (\w+). what is my name/, strings (name) ->
  @req.session.my_name = name
  @req.session.my_name
question /what is my name/, -> @req.session.my_name

# Trivia
question /what currency did Spain use before the Euro/, -> "peseta"
question /what colour is a banana/, -> "yellow"
question /who is the Prime Minister of Great Britain/, -> "David Cameron"
question /who played James Bond in the film Dr No/, -> "Sean Connery"
question /what is the twitter id of the organizer of this dojo/, -> "jhannes"
question /which city is the Eiffel tower in/, -> "Paris"

# Webshop
question /what products do you have for sale \(comma separated\)/, -> ("product#{x}" for x in [1..3])
question /how many dollars does one product(\d+) cost/, ints (cost) -> "#{cost}.00"
question /please put (\d+) product(\d+) in my shopping cart/, ints (quantity, cost) ->
  total = quantity * cost
  try
    @req.session.total += total
  catch error
    @req.session.total = total
  "okay"
question /what is my order total/, -> "#{@req.session.total}.00"



# Configure the route

app.get '/', (req, res) ->
  q = req.param("q")
  console.log "q:\"#{q}\""
  a = dispatch.answer q, req, res
  console.log "a:\"#{a}\""
  res.send a


# I choose you, Port 1337!

app.listen 1337
console.log "Listening on http://0.0.0.0:1337/"

