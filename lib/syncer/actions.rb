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

          at_exit do
            exit 1  unless $!.is_a?(SystemExit)
            exit_status = $!.status
            exit exit_status  if exit_status != 0

            # If vagrant up/reload/resume exited successfully, run rsync-auto.
            env[:machine].env.cli("rsync-auto")
          end

          @exit_registered = true
        end
      end

    end
  end
end
