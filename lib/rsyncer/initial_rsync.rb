module VagrantPlugins
  module Rsyncer
    class InitialRsync

      def initialize(app, env)
        @app = app
        @machine = env[:machine]
      end

      def call(env)
        @app.call(env)
        @machine.env.cli("rsyncer")
      end
    end
  end
end