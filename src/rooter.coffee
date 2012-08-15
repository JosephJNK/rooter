# Hash events
hash =
  listeners: []
  listen: (fn) -> rooter.hash.listeners.push fn
  trigger: (newHash=rooter.hash.value()) ->
    console.log "trigger called with hash #{newHash}"
    newHash = "/" if newHash is ""
    hash.pendingTeardown ->
      hash.pendingTeardown = (cb) -> cb()
      console.log "about to call a listener function"
      fn newHash for fn in rooter.hash.listeners
      return
  value: (newHash) ->
    if newHash
      window.location.hash = newHash
    return window.location.hash.replace '#', ''

hashTimer =
  listeners: []
  listen: (fn) -> rooter.hash.listeners.push fn
  trigger: (hash=rooter.hash.value()) ->
    hash = "/" if hash is ""
    console.log "hashTimer got triggered"
    fn hash for fn in rooter.hash.listeners
    return
  value: (newHash) ->
    if newHash
      rooter.hash.lastHash = newHash
      window.location.hash = newHash
    return window.location.hash.replace '#', ''

  lastHash: null
  check: ->
    currHash = rooter.hash.value()
    if currHash isnt rooter.hash.lastHash
      rooter.hash.lastHash = currHash
      rooter.hash.trigger currHash
    setTimeout rooter.hash.check, 100
    return

rooter =
  # Routing
  init: ->
    console.log "routes", rooter.routes
    rooter.hash.pendingTeardown = (cb) -> cb()
    rooter.hash.listen rooter.test
    return rooter.hash.check() if rooter.hash.check
    rooter.hash.trigger()

  routes: {}
  route: (expr, setup, teardown) ->
    pattern = "^#{expr}$"
    pattern = pattern
      .replace(/([?=,\/])/g, '\\$1') # escape
      .replace(/:([\w\d]+)/g, '([^/]*)') # name
      #.replace(/\*([\w\d]+)/g, '(.*?)') # splat

    rooter.routes[expr] =
      name: expr #removeme
      paramNames: expr.match /:([\w\d]+)/g
      pattern: new RegExp pattern
      setup: setup
      teardown: if teardown then teardown else (cb) -> cb()
      beforeFilters: []
    return

  runBeforeFilters: (destination, routeInput, cb) ->
    console.log "about to run before filters for #{destination.name}"
    runFilters = (filterArray) ->
      console.log "destination is currently #{destination.name}"
      if filterArray.length is 0
        console.log "done running filters, returning... and destination is #{destination.name}"
        return cb null
      filterArray.shift() routeInput, (err) ->
        console.log "ran a filter"
        console.log "it returned: #{err}"
        return cb err if err
        console.log "gonna run another filter"
        runFilters filterArray

    filters = destination.beforeFilters.slice 0
    runFilters filters

  test: (attemptedHash) ->
    #TODO move async shit out of for loop
    for url, destination of rooter.routes
      if matches = destination.pattern.exec attemptedHash
        routeInput = {}
        if destination.paramNames
          args = matches[1..]
          routeInput[name.substring(1)] = args[idx] for name, idx in destination.paramNames
        rooter.runBeforeFilters destination, routeInput, (err) ->
          unless err
            hash.pendingTeardown = destination.teardown
            destination.setup routeInput
    return

  addBeforeFilter: (expr, filter) ->
    return unless rooter.routes[expr]
    rooter.routes[expr].beforeFilters.push filter

if typeof window.onhashchange isnt 'undefined'
  rooter.hash = hash
  window.onhashchange = -> rooter.hash.trigger rooter.hash.value()
else
  rooter.hash = hashTimer
  setTimeout rooter.hash.check, 100
window.rooter = rooter
