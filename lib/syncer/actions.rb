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

          # If Vagrant up/reload/resume exited successfully, run this rsync-auto
          at_exit do
            env[:machine].env.cli("rsync-auto")  if $!.status == 0
          end
        end
      end

    end
  end
end
