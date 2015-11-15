module Vagrant
  module Syncer
    module Actions
      class StartSyncer

        def initialize(app, env)
          @app = app
        end

        def call(env)
          @app.call(env)

          return  unless env[:machine].config.syncer.run_on_startup

          # When Vagrant is finished, run our syncer if Vagrant exited successfully
          at_exit do
            env[:machine].env.cli("syncer")  if $!.status == 0
          end
        end
      end

    end
  end
end