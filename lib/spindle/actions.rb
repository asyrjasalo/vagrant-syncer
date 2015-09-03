module Vagrant
  module Spindle
    module Actions
      class Base
        def initialize(app, env)
          @app = app
        end
      end

      class Up < Base
        def call(env)
          machine = Machine.new(env[:machine])
          machine.full
          @app.call(env)
        end
      end

      class Resume < Up; end
      class Reload < Up; end
    end
  end
end