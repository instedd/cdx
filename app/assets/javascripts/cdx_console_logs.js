(function() {
  var originals = {};
  window.__cdx_logs = [];

  function capture_logs(name) {
    originals[name] = window.console[name];

    window.console[name] = function () {
      var args = Array.prototype.map.call(arguments, function (x) {
        return x.toString();
      });
      window.__cdx_logs.push([name.toUpperCase()].concat(args));

      return originals[name].apply(null, arguments);
    }
  }

  capture_logs("debug");
  capture_logs("error");
  capture_logs("info");
  capture_logs("log");
  capture_logs("trace");
  capture_logs("warn");
})();
