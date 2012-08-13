# Hash events
hash =
  listeners: []
  listen: (fn) -> rooter.hash.listeners.push fn
  trigger: (hash=rooter.hash.value()) ->
    hash = "/" if hash is ""
    fn hash for fn in rooter.hash.listeners
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
    rooter.hash.listen rooter.test
    return rooter.hash.check() if rooter.hash.check
    rooter.hash.trigger()

  routes: {}
  route: (expr, fn) ->
    pattern = "^#{expr}$"
    pattern = pattern
      .replace(/([?=,\/])/g, '\\$1') # escape
      .replace(/:([\w\d]+)/g, '([^/]*)') # name
      #.replace(/\*([\w\d]+)/g, '(.*?)') # splat

    rooter.routes[expr] =
      paramNames: expr.match /:([\w\d]+)/g
      pattern: new RegExp pattern
      fn: fn
      beforeFilters: []
    return

  runBeforeFilters: (destination, routeInput, cb) ->
    runFilters = (filterArray) ->
      return cb null if filterArray.length is 0
      filterArray.shift() routeInput, (err) ->
        return cb err if err
        runFilters filterArray

    filters = destination.beforeFilters.slice 0
    runFilters filters

  test: (hash) ->
    for url, destination of rooter.routes
      if matches = destination.pattern.exec hash
        routeInput = {}
        if destination.paramNames
          args = matches[1..]
          routeInput[name.substring(1)] = args[idx] for name, idx in destination.paramNames
        rooter.runBeforeFilters destination, routeInput, (err) ->
          unless err
            destination.fn routeInput
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
