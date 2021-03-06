// Generated by CoffeeScript 1.3.3
(function() {
  var hash, hashTimer, rooter,
    __slice = [].slice;

  hash = {
    listeners: [],
    listen: function(fn) {
      return rooter.hash.listeners.push(fn);
    },
    trigger: function(newHash) {
      var _base, _ref;
      if (newHash == null) {
        newHash = rooter.hash.value();
      }
      if (newHash === "") {
        newHash = "/";
      }
      if ((_ref = (_base = rooter.hash).pendingTeardown) == null) {
        _base.pendingTeardown = function(cb) {
          return cb();
        };
      }
      return rooter.hash.pendingTeardown(function() {
        var fn, _i, _len, _ref1;
        rooter.hash.pendingTeardown = function(cb) {
          return cb();
        };
        _ref1 = rooter.hash.listeners;
        for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
          fn = _ref1[_i];
          fn(newHash);
        }
      });
    },
    value: function(newHash) {
      if (newHash) {
        window.location.hash = newHash;
      }
      return window.location.hash.replace('#', '');
    }
  };

  hashTimer = {
    listeners: [],
    listen: function(fn) {
      return rooter.hash.listeners.push(fn);
    },
    trigger: function(hash) {
      var fn, _i, _len, _ref;
      if (hash == null) {
        hash = rooter.hash.value();
      }
      if (hash === "") {
        hash = "/";
      }
      _ref = rooter.hash.listeners;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        fn = _ref[_i];
        fn(hash);
      }
    },
    value: function(newHash) {
      if (newHash) {
        rooter.hash.lastHash = newHash;
        window.location.hash = newHash;
      }
      return window.location.hash.replace('#', '');
    },
    lastHash: null,
    check: function() {
      var currHash;
      currHash = rooter.hash.value();
      if (currHash !== rooter.hash.lastHash) {
        rooter.hash.lastHash = currHash;
        rooter.hash.trigger(currHash);
      }
      setTimeout(rooter.hash.check, 100);
    }
  };

  rooter = {
    init: function() {
      rooter.hash.pendingTeardown = function(cb) {
        return cb();
      };
      rooter.hash.listen(rooter.test);
      if (rooter.hash.check) {
        return rooter.hash.check();
      }
      return rooter.hash.trigger();
    },
    routes: {},
    route: function(expr, setup, teardown) {
      var pattern;
      pattern = "^" + expr + "$";
      pattern = pattern.replace(/([?=,\/])/g, '\\$1').replace(/:([\w\d]+)/g, '([^/]*)').replace(/(\$)$/g, '(?:\\?(.*))?$');
      rooter.routes[expr] = {
        name: expr,
        paramNames: expr.match(/:([\w\d]+)/g),
        pattern: new RegExp(pattern),
        setup: setup,
        teardown: teardown ? teardown : function(cb) {
          return cb();
        },
        beforeFilters: []
      };
    },
    runBeforeFilters: function(destination, routeInput, cb) {
      var currentArgs, filters, runFilters;
      if (routeInput == null) {
        routeInput = {};
      }
      currentArgs = routeInput;
      runFilters = function(filterArray) {
        var currentFunction;
        if (filterArray.length === 0) {
          return cb(null, currentArgs);
        }
        currentFunction = filterArray.shift();
        return currentFunction(currentArgs, function(err, newArgs) {
          if (newArgs == null) {
            newArgs = currentArgs;
          }
          currentArgs = newArgs;
          if (err != null) {
            return cb(err);
          }
          return runFilters(filterArray);
        });
      };
      filters = destination.beforeFilters.slice(0);
      return runFilters(filters);
    },
    test: function(attemptedHash) {
      var args, destination, getDestination, idx, junk, matches, name, queryString, routeInput, _i, _j, _len, _ref, _ref1;
      getDestination = function() {
        var destination, matches, url, _ref;
        _ref = rooter.routes;
        for (url in _ref) {
          destination = _ref[url];
          if (matches = destination.pattern.exec(attemptedHash)) {
            return [destination, matches];
          }
        }
        return [null, null];
      };
      _ref = getDestination(), destination = _ref[0], matches = _ref[1];
      if (!destination) {
        return;
      }
      routeInput = {};
      if (destination.paramNames) {
        args = matches.slice(1);
        _ref1 = destination.paramNames;
        for (idx = _i = 0, _len = _ref1.length; _i < _len; idx = ++_i) {
          name = _ref1[idx];
          routeInput[name.substring(1)] = args[idx];
        }
      }
      if (attemptedHash.indexOf('?' !== -1)) {
        junk = 2 <= matches.length ? __slice.call(matches, 0, _j = matches.length - 1) : (_j = 0, []), queryString = matches[_j++];
      }
      return rooter.runBeforeFilters(destination, routeInput, function(err, modifiedArgs) {
        if (!err) {
          hash.pendingTeardown = destination.teardown;
          return destination.setup(modifiedArgs, queryString);
        }
      });
    },
    addBeforeFilter: function(expr, filter) {
      if (!rooter.routes[expr]) {
        return;
      }
      return rooter.routes[expr].beforeFilters.push(filter);
    }
  };

  if (typeof window.onhashchange !== 'undefined') {
    rooter.hash = hash;
    window.onhashchange = function() {
      return rooter.hash.trigger(rooter.hash.value());
    };
  } else {
    rooter.hash = hashTimer;
    setTimeout(rooter.hash.check, 100);
  }

  window.rooter = rooter;

}).call(this);
