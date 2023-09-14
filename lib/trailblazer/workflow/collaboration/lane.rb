module Trailblazer
  module Workflow
    class Collaboration
      def self.Lane(intermediate, **tuples)
# pp intermediate
# raise
        # 1. {intermediate} has to provide all data we need (e.g. {type})

        implementation = intermediate.wiring.collect do |task_ref, links|
          id = task_ref.id

          implementation_task =
            case task_ref.data[:type]
            when :start_event
              Lane.compile_start_event(task_ref, links)
            when :task
              # run some kind of Normalizer for tasks
              id = task_ref.id
              label = task_ref.data.fetch(:label)

              options_from_user = tuples.fetch(label) # DISCUSS: currently, we're keying tasks by label, not ID.

              Lane.compile_task(task_ref, links, options: options_from_user)
            when :suspend
              Lane.compile_suspend(task_ref, links)
            when :catch_event
              Lane.compile_catch_event(task_ref, links)
            when :throw_event
              Lane.compile_throw_event(task_ref, links)
            when :terminus
              Lane.compile_terminus(task_ref, links)
            else
              raise "unknown type #{task_ref.data.fetch(:type).inspect}"
            end

          [id, implementation_task]
        end.to_h

        # pp implementation

        schema = Activity::Schema::Intermediate::Compiler.(intermediate, implementation) # implemented in the generic {trailblazer-activity} gem.

        Activity.new(schema)
      end

      module Lane
        railway_normalizer  = Activity::Railway::DSL.Normalizer()
        default_outputs_row = railway_normalizer.to_a.find { |row| row.id == "activity.default_outputs" }


        Normalizer = Activity::TaskWrap::Pipeline.new(
          {
            "activity.normalize_step_interface"       => Activity::DSL::Linear::Normalizer.Task(Activity::DSL::Linear::Normalizer.method(:normalize_step_interface)), # :options is a hash, and :method marked for wrapping.
            "activity.normalize_normalizer_options"   => Activity::DSL::Linear::Normalizer.Task(Activity::DSL::Linear::Normalizer.method(:merge_normalizer_options)),
            "activity.normalize_non_symbol_options"   => Activity::DSL::Linear::Normalizer.Task(Activity::DSL::Linear::Normalizer.method(:normalize_non_symbol_options)),
            "activity.normalize_context"              => Activity::DSL::Linear::Normalizer.method(:normalize_context),
            "activity.wrap_task_with_step_interface"  => Activity::DSL::Linear::Normalizer.Task(Activity::DSL::Linear::Normalizer.method(:wrap_task_with_step_interface)),
            # until here, we got an options hash containing :task (TODO: add wiring, ideally with output_tuples interface)


          }.collect { |id, task| Activity::TaskWrap::Pipeline.Row(id, task) } + [default_outputs_row]
        )

        module_function

        def compile_start_event(task_ref, intermediate_links, **)
          # :a => Schema::Implementation::Task(Implementing.method(:a),           [Activity::Output(Activity::Right,       :success), Activity::Output(Activity::Left, :failure)],        [a_extension_1, a_extension_2]),
          start_event = Activity::Start.new(semantic: :default)

          Activity::Schema::Implementation.Task(
            start_event,
            implementation_outputs_for(
              intermediate_links,
              outputs: {success: Activity::Output(Activity::Right, :success)} # normally, the DSL would provide default outputs. for Start, we don't need this.
            )
          )
        end

        def compile_terminus(task_ref, intermediate_links, **)
          # :a => Schema::Implementation::Task(Implementing.method(:a),           [Activity::Output(Activity::Right,       :success), Activity::Output(Activity::Left, :failure)],        [a_extension_1, a_extension_2]),
          start_event = Activity::End.new(semantic: task_ref.id)

          Activity::Schema::Implementation.Task(
            start_event,
            implementation_outputs_for(
              intermediate_links,
              outputs: {}
            )
          )
        end

        def compile_task(task_ref, intermediate_links, **options)
          ctx = {
            **options,
            normalizer_options: {
              step_interface_builder: Activity::DSL::Linear::Strategy::DSL.method(:build_circuit_task_for_step),
            }
          }

          wrap_ctx, _ = Lane::Normalizer.(ctx, nil)

          Activity::Schema::Implementation.Task(
            wrap_ctx[:task],
            implementation_outputs_for(
              intermediate_links,
              outputs: wrap_ctx[:outputs]
            )
          )
        end

        def compile_suspend(task_ref, intermediate_links, **)
          # :a => Schema::Implementation::Task(Implementing.method(:a),           [Activity::Output(Activity::Right,       :success), Activity::Output(Activity::Left, :failure)],        [a_extension_1, a_extension_2]),
          start_event = Workflow::Event::Suspend.new(
            semantic: [:suspend, task_ref.id], # TODO: strictly speaking, we need different semantics here for different suspends.
            **task_ref.data
          )

          Activity::Schema::Implementation.Task(
            start_event,
            implementation_outputs_for(
              intermediate_links,
              outputs: {success: Activity::Output(Activity::Right, :success)}
            )
          )
        end

        def compile_throw_event(task_ref, intermediate_links, **)
          # :a => Schema::Implementation::Task(Implementing.method(:a),           [Activity::Output(Activity::Right,       :success), Activity::Output(Activity::Left, :failure)],        [a_extension_1, a_extension_2]),
          start_event = Workflow::Event::Throw.new(
            semantic: [:throw, task_ref.id], # FIXME: use Activity::Start without semantic (or default?)?
            **task_ref.data
          )

          Activity::Schema::Implementation.Task(
            start_event,
            implementation_outputs_for(
              intermediate_links,
              outputs: {success: Activity::Output(Activity::Right, :success)}
            )
          )
        end

        def compile_catch_event(task_ref, intermediate_links, **)
          # :a => Schema::Implementation::Task(Implementing.method(:a),           [Activity::Output(Activity::Right,       :success), Activity::Output(Activity::Left, :failure)],        [a_extension_1, a_extension_2]),
          start_event = Workflow::Event::Catch.new(
            semantic: [:catch, task_ref.id], # FIXME: use Activity::Start without semantic (or default?)?
            **task_ref.data
          )

          Activity::Schema::Implementation.Task(
            start_event,
            implementation_outputs_for(
              intermediate_links,
              outputs: {success: Activity::Output(Activity::Right, :success)}
            )
          )
        end

        # @param outputs Outputs provided by the DSL.
        def implementation_outputs_for(intermediate_links, outputs:) # TODO: figure out if {:outputs} contains more outgoing connections than defined in intermediate_links from intermediate.
          # TODO: currently, we don't allow links not defined in intermediate/diagram.
          intermediate_links.collect do |intermediate_out|
            semantic = intermediate_out.semantic.to_sym

            outputs.fetch(semantic)
          end
        end

        def compile_implementation(ctx, tasks:, intermediate:, **)


        end
      end
    end
  end
end
