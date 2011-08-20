express = require 'express'
mongoose = require 'mongoose'
sessionStore = require("connect-mongoose")(express)
answer = (require "./rules").answer

# Connect to MongoDB

mongo_uri = "mongodb://localhost/bodilpwnz"
console.log "Connecting to #{mongo_uri}"
mongoose.connect mongo_uri


# Configure the Express HTTP server

app = exports.server = express.createServer()

# Configure an HTTP session handler using MongoDB to persist session state

app.use express.cookieParser()
app.use express.session
  secret: "foo"
  store: new sessionStore()


# Configure the route

app.get '/', (req, res) ->
  q = req.param("q")
  console.log "q:\"#{q}\""
  a = answer q, req, res
  console.log "a:\"#{a}\""
  res.send a
