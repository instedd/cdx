# TODO: Upgrade to oj 3.10.1 to leverage Oj.optimize_rails to automatically
#       override JSON and ActiveSupport::JSON with full compatibility.
Oj.default_options = {mode: :compat}
