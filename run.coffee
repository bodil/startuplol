#!/usr/bin/env coffee

config =
  # application title, used in notifications
  name: "runlol"
  # command used to launch your app
  spawn_command: "coffee app.coffee"
  # list of regexps matching paths that should not be watched
  ignore: [ /^node_modules|public$/ ]
  # environment variables to pass to the child process
  local_env: {}
  # if true, will write compiled .js files to the filesystem
  compile_coffee: false
  # list of regexps matching test files
  tests: [ /^test\/.*\.coffee$/ ]
  # your test runner, tests to run are appended to the command line
  test_command: "expresso -I #{__dirname}"
  # minimum required number of milliseconds between acting on file changes
  grace_period: 1000
  # list of regexps matching Zappa files (requires compile_coffee == true)
  zappa_files: [ /\.zappa$/ ]

fs = require "fs"
child_process = require "child_process"
path = require "path"
coffee = require "coffee-script"
events = require "events"

config[key] = value for own key, value of eval coffee.compile (fs.readFileSync "run.cson", "utf-8"), bare: true

try
  libnotify = require "gnomenotify"
  libnotify.notify_init "runlol"

notify = (message, icon) ->
  icon = if icon? then icon else "dialog-error"
  if libnotify
    n = new libnotify.Notification config.name, message, icon
    n.set_hint "x-canonical-append", ""
    n.show()

exists = (path) ->
  try
    fs.statSync path
    true
  catch error
    false

simplify = (path) -> if path[0...__dirname.length] is __dirname then path[__dirname.length+1..] else path
inres = (item, re_list) -> (true for re in re_list when item.match re).length
isdir = (path) -> (fs.statSync path).isDirectory()
iscoffee = (path) -> not not path.match(/\.coffee$/)
istest = (path) -> inres (simplify path), config.tests

scan = (base, list) ->
  list ?= {}
  for file in fs.readdirSync base when file[0] isnt "." and not inres file, config.ignore
    file = path.join base, file
    if isdir file then scan file, list else list[file] = true if (iscoffee file) and (file isnt __filename)
  list

isnewer = (first, second) ->
    return (fs.statSync first).mtime > (fs.statSync second).mtime

class CompileError
  constructor: (@file, @error) ->

compile = (inpath) ->
  return if (istest inpath) or (not iscoffee inpath)
  outpath = path.join (path.dirname inpath), (path.basename inpath, ".coffee") + ".js"
  if (not exists outpath) or (isnewer inpath, outpath)
    console.log "Compiling #{simplify inpath}"
    try
      js = coffee.compile (fs.readFileSync inpath, "utf8"), bare: not not inres inpath, config.zappa_files
    catch error
      body = "In file #{simplify inpath}: #{error.message}"
      console.log body
      notify body
      throw new CompileError inpath, error
    js = """require('zappa').run(function(){#{js}}, { port: [ parseInt(process.env.PORT, 10) || 5678 ] });""" if inres inpath, config.zappa_files
    fs.writeFileSync outpath, js if config.compile_coffee

test = (tests, callback) ->
  if process.env.APP_ENV isnt "heroku"
    spawn_args = (config.test_command.split " ").concat tests
    spawn_cmd = spawn_args.shift()
    console.log "Running #{spawn_cmd} " + spawn_args.join " "
    failures = "Some"
    child = child_process.spawn spawn_cmd, spawn_args, cwd: __dirname
    child.on "exit", (code, signal) ->
      if code? and code > 0
        notify if failures == 1 then "1 test is failing." else "#{failures} tests are failing."
        console.log "Test process ended with return code #{code}"
      console.log "Test process terminated with signal #{signal}" if signal?
      callback?()
    output = (data) ->
      process.stdout.write data.toString("utf8")
      data = ("" + data).replace /\u001b\[.*?m/g, ""
      m = /fail(?:ures|ing|ed):?\s*(\d+)/gmi.exec data
      failures = parseInt m[1], 10 if m
    child.stdout.on "data", output
    child.stderr.on "data", output
  else
    callback?()

runtests = (callback) -> test (simplify t for own t of scan __dirname when istest t), callback

class Watcher extends events.EventEmitter
  constructor: ->
    super()
    @watched = []
    @lastStamp = 0

  watch: (file) ->
    @watched.push file
    fs.watchFile file, (curr, prev) =>
      stamp = Date.now()
      if (stamp - config.grace_period) > @lastStamp
        @emit "fileChanged", file
        @lastStamp = stamp

  clear: ->
    fs.unwatchFile file for file in @watched
    @watched = []

class Launcher
  constructor: ->
    process.on "SIGINT", @onInterrupt
    @watcher = new Watcher
    @watcher.on "fileChanged", @onFileChanged

  onInterrupt: =>
    console.log "Exiting on SIGINT"
    if @child?
      console.log "Terminating child process"
      @child.removeListener "exit", @onChildExit
      @child.on "exit", (code, signal) =>
        console.log "kthxbai"
        process.exit 0
      @child.kill "SIGINT"
    else
      console.log "kthxbai"
      process.exit 0

  onFileChanged: (file) =>
    console.log "File changed:", file
    if (istest file) and (exists file)
      test [simplify file]
    else
      @run()

  compile: ->
    compile script for own script of scan __dirname

  watch: ->
    @watcher.clear()
    @files = (file for own file of scan __dirname)
    @watcher.watch file for file in @files
    if not @watchTimer?
      @watchTimer = setInterval @watchForNew, 1000

  watchForNew: =>
    if (file for own file of scan __dirname).length isnt @files.length
      @run()

  respawn: ->
    if @child?
      @child.removeListener "exit", @onChildExit
      @child.on "exit", (code, signal) =>
        console.log "Restarting child process"
        @spawn()
      @child.kill()
    else
      @spawn()

  spawn: ->
    @errorlog = ""
    child_env = {}
    child_env[key] = value for own key, value of config.local_env
    child_env[key] = value for own key, value of process.env
    spawn_args = config.spawn_command.split(" ")
    spawn_cmd = spawn_args.shift()
    @child = child_process.spawn spawn_cmd, spawn_args,
      cwd: __dirname
      env: child_env
    @onChildExit = (code, signal) =>
      @child = null
      console.log "Child process ended with return code #{code}" if code?
      console.log "Child process terminated with signal #{signal}" if signal?
      log = ((@errorlog.split "\n").slice 0, 4).join "\n"
      notify log, "dialog-warning" if code?
    @child.on "exit", @onChildExit
    @child.stdout.on "data", (data) =>
      process.stdout.write "CHILD: " + data.toString("utf8")
    @child.stderr.on "data", (data) =>
      process.stdout.write "ERROR: " + data.toString("utf8")
      @errorlog += data

  run: ->
    runtests =>
      try
        @compile()
      catch error
        if error instanceof CompileError
          console.log "Compilation failed!"
          @watch()
          return
        else
          throw error
      if process.env.APP_ENV isnt "heroku"
        @watch()
      @respawn()

(new Launcher).run()

