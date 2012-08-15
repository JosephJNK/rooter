# Hash events
hash =
  listeners: []
  listen: (fn) -> rooter.hash.listeners.push fn
  trigger: (newHash=rooter.hash.value()) ->
    newHash = "/" if newHash is ""
    hash.pendingTeardown ->
      hash.pendingTeardown = (cb) -> cb()
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
    runFilters = (filterArray) ->
      if filterArray.length is 0
        return cb null
      filterArray.shift() routeInput, (err) ->
        return cb err if err
        runFilters filterArray

    filters = destination.beforeFilters.slice 0
    runFilters filters

  test: (attemptedHash) ->
    getDestination = () ->
      for url, destination of rooter.routes
        return [destination, matches] if matches = destination.pattern.exec attemptedHash
      return [null, null]

    [destination, matches] = getDestination()
    return unless destination
    routeInput = {}
    if destination.paramNames
      args = matches[1..]
      routeInput[name.substring(1)] = args[idx] for name, idx in destination.paramNames
    rooter.runBeforeFilters destination, routeInput, (err) ->
      unless err
        hash.pendingTeardown = destination.teardown
        destination.setup routeInput

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
