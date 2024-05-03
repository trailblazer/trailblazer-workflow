module Trailblazer
  module Workflow
    module Task
      # Discovery task: discover, serialize, create test plan, create state table/state guards
      module Discover
        module_function

        # DISCUSS: what about running this before we have a schema?
        def call(namespace:, target_dir:, test_filename:, json_filename:, **discovery_options)

          filepath = Filepath.new(target_dir)

          schema_filename         = filepath.("schema.rb")
          state_guard_filename    = filepath.("state_guards.rb")
          state_table_filename    = filepath.("generated/state_table.rb")
          iteration_set_filename  = filepath.("generated/iteration_set.json")

          states, schema, parsed_structure = Trailblazer::Workflow::Discovery.(
            json_filename: json_filename,
            **discovery_options
            # run_multiple_times: run_multiple_times,
          )

          lanes_cfg = schema.to_h[:lanes]

          iteration_set = Trailblazer::Workflow::Introspect::Iteration::Set.from_discovered_states(states, lanes_cfg: lanes_cfg)

          create_directory_for_generated_files(filepath.("generated"))

          create_serialized_iteration_set(iteration_set, iteration_set_filename: iteration_set_filename, lanes_cfg: lanes_cfg)

          Produce::TestPlan.(
            iteration_set,
            lanes_cfg: lanes_cfg,
            test_filename: test_filename,
            namespace: namespace,
            iteration_set_filename: iteration_set_filename
          )

          Produce::StateGuards.(
            iteration_set,
            lanes_cfg: lanes_cfg,
            filename: state_guard_filename,
            state_table_filename: state_table_filename,
            namespace: namespace,
          )

          Produce::Schema.(
            parsed_structure: parsed_structure,
            namespace: namespace,
            filename: schema_filename,
            json_filename: json_filename,
          )

          return states
        end


    # assert_equal testing_json, File.read("test/iteration_json.json")

    # iteration_set_from_json = Trailblazer::Workflow::Introspect::Iteration::Set::Deserialize.(JSON.parse(testing_json), lanes_cfg: lanes_cfg)

    # assert_equal JSON.pretty_generate(Trailblazer::Workflow::Introspect::Iteration::Set::Serialize.(iteration_set, lanes_cfg: lanes_cfg)), JSON.pretty_generate(Trailblazer::Workflow::Introspect::Iteration::Set::Serialize.(iteration_set_from_json, lanes_cfg: lanes_cfg))

        def find_start_task_position(start_activity_json_id, lanes_cfg)
          start_activity = lanes_cfg.(json_id: start_activity_json_id)[:activity]

          start_task = start_activity.to_h[:circuit].to_h[:start_task]

          _start_task_position = Trailblazer::Workflow::Collaboration::Position.new(start_activity, start_task)
        end

        def create_serialized_iteration_set(iteration_set, iteration_set_filename:, lanes_cfg:)
          interation_set_json = JSON.pretty_generate(Trailblazer::Workflow::Introspect::Iteration::Set::Serialize.(iteration_set, lanes_cfg: lanes_cfg))

          File.write(iteration_set_filename, interation_set_json)
        end

        def create_directory_for_generated_files(target_path)
          FileUtils.mkdir_p(target_path)
        end


        module Produce
          module TestPlan
            module_function

            def call(iteration_set, lanes_cfg:, test_filename:, namespace:, input: {}, iteration_set_filename:)
              test_plan_comment_header = Trailblazer::Workflow::Test::Plan::Introspect.(iteration_set, lanes_cfg: lanes_cfg)

              assertions = Trailblazer::Workflow::Test::Plan.for(iteration_set, lanes_cfg: lanes_cfg, input: input)


              test_content = %(=begin
  #{test_plan_comment_header}
=end

  require "test_helper"

  class #{namespace.gsub("::", "_")}CollaborationTest < Minitest::Spec
    include Trailblazer::Workflow::Test::Assertions
    require "trailblazer/test/assertions"
    include Trailblazer::Test::Assertions # DISCUSS: this is for assert_advance and friends.

    it "can run the collaboration" do
      schema = #{namespace}::Schema
      test_plan = Trailblazer::Workflow::Introspect::Iteration::Set::Deserialize.(JSON.parse(File.read("#{iteration_set_filename}")), lanes_cfg: schema.to_h[:lanes])

      #{assertions.join("\n")}
    end
  end
  )

              File.write(test_filename, test_content)
            end
          end

          module StateGuards
            module_function

            def call(iteration_set, filename:, state_table_filename:, lanes_cfg:, namespace:, **)
              # ruby_output = Trailblazer::Workflow::Introspect::StateTable::Generate.(iteration_set, lanes_cfg: lanes_cfg, namespace: namespace)
              _, (ctx, _) = Trailblazer::Workflow::Generate::StateTable.invoke([{iteration_set: iteration_set, lanes_cfg: lanes_cfg, namespace: namespace}, {}])
              state_table_output = ctx[:snippet]
              _, (ctx, _) = Trailblazer::Workflow::Generate::StateGuards.invoke([{rows: ctx[:rows], namespace: namespace}, {}])
              ruby_output = ctx[:snippet]

              File.write(state_table_filename, state_table_output)
              File.write(filename, ruby_output)
            end
          end

          class Schema
            def self.call(parsed_structure:, namespace:, filename:, json_filename:, **)
              _, (ctx, _) = Trailblazer::Workflow::Generate::Schema.invoke([{parsed_structure: parsed_structure, namespace: namespace, json_filename: json_filename}, {}])
              ruby_output = ctx[:snippet]

              File.write(filename, ruby_output)
            end
          end

        end # Produce

        class Filepath
          def initialize(base_path)
            @base_path = base_path
            freeze
          end

          def call(filename) # TODO: defaulting?
            File.join(@base_path, filename)
          end
        end
      end
    end # Task
  end
end
