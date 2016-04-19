module Vagrant
  module Syncer
    module Actions
      class StartSyncer

        def initialize(app, env)
          @app = app
          @exit_registered = false
        end

        def call(env)
          @app.call(env)

          return  unless env[:machine].config.syncer.run_on_startup
          return  if @exit_registered

          # If vagrant up/reload/resume exited successfully, run rsync-auto.
          at_exit do
            if $! && $!.status == 0
              env[:machine].env.cli("rsync-auto")
            end
          end

          @exit_registered = true
        end
      end

    end
  end
end
