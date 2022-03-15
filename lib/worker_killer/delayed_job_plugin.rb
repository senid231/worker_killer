require 'worker_killer/memory_limiter'
require 'worker_killer/count_limiter'

module WorkerKiller
  module DelayedJobPlugin
    module JobsLimiter
      module_function

      def new(killer:, **options)
        ::WorkerKiller::DelayedJobPlugin.build_plugin(
          killer: killer,
          limiter_class: ::WorkerKiller::CountLimiter,
          **options
        )
      end
    end

    module OOMLimiter
      module_function

      def new(killer: nil, **options)
        ::WorkerKiller::DelayedJobPlugin.build_plugin(
          killer: killer,
          limiter_class: ::WorkerKiller::MemoryLimiter,
          **options
        )
      end
    end

    module_function

    def build_plugin(killer: nil, limiter_class:, **options)
      limiter = limiter_class.new(**options)
      killer ||= ::WorkerKiller::Killer::DelayedJob.new
      Class.new(Delayed::Plugin) do
        callbacks do |lifecycle|
          lifecycle.after(:perform) do |worker, *_args|
            killer.kill(limiter.started_at, dj: worker) if limiter.check
          end
        end
      end
    end

  end
end

