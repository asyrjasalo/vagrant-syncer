module Vagrant
  module Spindle
    module Actions
      class Base
        def initialize(app, env)
          @machine = env[:machine]
        end
      end

      class Up < Base
        def call(env)
          # TODO: Start rsyncer
        end
      end

      class Halt < Base
        def call(env)
          # TODO: Stop rsyncer
        end
      end

      class Resume < Up; end
      class Reload < Up; end
      class Provision < Up; end
      class Suspend < Halt; end
      class Destroy < Halt; end
    end
  end
end