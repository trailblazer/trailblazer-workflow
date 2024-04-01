require "test_helper"

# high-level unit test that shows the user's interface.
class AdvanceTest < Minitest::Spec
  include BuildSchema
  include DiscoveredStates

  it "what" do
    # TODO: this is something that shouldn't be done every time.
    states, schema, lanes_cfg, message_flow = states()

    iteration_set = Trailblazer::Workflow::Introspect::Iteration::Set.from_discovered_states(states, lanes_cfg: lanes_cfg)
    # Serialize/deserialize the Set, as this will always be the case in a real environment.
    serialized_iteration_set = JSON.dump(Trailblazer::Workflow::Introspect::Iteration::Set::Serialize.(iteration_set, lanes_cfg: lanes_cfg))
    iteration_set = Trailblazer::Workflow::Introspect::Iteration::Set::Deserialize.(JSON.parse(serialized_iteration_set), lanes_cfg: lanes_cfg)

    state_guards = state_guards()


=begin
    ctx = {params: [], seq: [], process_model: nil}

    # TODO: this should be suitable to be dropped into an endpoint.
    signal, (ctx, flow_options), configuration = Trailblazer::Workflow::Advance.(
      ctx,
      **schema.to_h,
      event_label: "☝ ⏵︎Create",
      # lanes_cfg: lanes_cfg, # TODO: make this part of {schema}.

      iteration_set: iteration_set, # this is basically the "dictionary" for lookups of positions.
      state_guards: state_guards,
    )

    assert_equal signal.inspect, %(Trailblazer::Activity::Right)
    assert_equal configuration.class, Trailblazer::Workflow::Collaboration::Configuration # FIXME: better test.

    #@ update invalid
    signal, (ctx, flow_options) = Trailblazer::Workflow::Advance.(
      {create: false, seq: [], process_model: nil},
      **schema.to_h,
      event_label: "☝ ⏵︎Create",
      iteration_set: iteration_set, # this is basically the "dictionary" for lookups of positions.
      state_guards: state_guards,
    )

    assert_equal signal.inspect, %(Trailblazer::Activity::Left)
=end
    require "trailblazer/endpoint"
    require "trailblazer/macro/model/find"

    protocol_template = Class.new(Trailblazer::Endpoint::Protocol) do
      # step Trailblazer::Activity::Railway::Model::Find(Posting, find_by: :id, not_found_terminus: true), after: :authenticate # FIXME: why do we need FQ constant?

      def authenticate(*)
        true
      end

      def policy(*)
        true
      end
    end

    protocol_template_with_model = Class.new(protocol_template) do
      step Trailblazer::Activity::Railway::Model::Find(Posting, find_by: :id, not_found_terminus: true), after: :authenticate # FIXME: why do we need FQ constant?
    end



    advance_protocol = Trailblazer::Endpoint.build_protocol(protocol_template, domain_activity: Trailblazer::Workflow::Advance,
      protocol_block: ->(*) { {Trailblazer::Activity::Railway.Output(:not_authorized) => Trailblazer::Activity::Railway.Track(:not_authorized)} }
    )

    advance_protocol_with_model = Trailblazer::Endpoint.build_protocol(protocol_template_with_model, domain_activity: Trailblazer::Workflow::Advance,
      protocol_block: ->(*) { {Trailblazer::Activity::Railway.Output(:not_authorized) => Trailblazer::Activity::Railway.Track(:not_authorized)} }
    )

    # action_protocol = Trailblazer::Endpoint.build_protocol(Protocol, domain_activity: Create, protocol_block: ->(*) { {Output(:not_found) => Track(:not_found)} })
    action_adapter  = Trailblazer::Endpoint::Adapter.build(advance_protocol) # build the simplest Adapter we got.
    action_adapter_with_model  = Trailblazer::Endpoint::Adapter.build(advance_protocol_with_model) # build the simplest Adapter we got.

    ctx = {
    }


    original_flow_options = {
      event_label: "☝ ⏵︎Create",
      **schema.to_h,
      iteration_set: iteration_set,
      state_guards:  state_guards,
    }

    default_matcher = Trailblazer::Endpoint::Matcher.new(
      success:    ->(*) { raise },
    )
    matcher_block = -> do
      success { |ctx, seq:, **| render seq.inspect }
      failure { |ctx, model:, **| render "failed: #{model}" }
      not_found { |ctx, params:, **| render "404 not found: #{params[:id]}" }
    end

    def render(text)
      @render = text
    end

# Create
    flow_options = original_flow_options.merge(event_label: "☝ ⏵︎Create",)
    Trailblazer::Endpoint::Runtime.({params: {}, seq: []}, adapter: action_adapter, default_matcher: default_matcher, matcher_context: self, flow_options: flow_options, &matcher_block)
    assert_equal @render, %([:ui_create, :create])

# Update
    flow_options = original_flow_options.merge(event_label: "☝ ⏵︎Update",)
    Trailblazer::Endpoint::Runtime.({params: {id: 1}, seq: []}, adapter: action_adapter_with_model, default_matcher: default_matcher, matcher_context: self, flow_options: flow_options, &matcher_block)
    assert_equal @render, %([:ui_update, :update])

# Update: Protocol doesn't find model
    flow_options = original_flow_options.merge(event_label: "☝ ⏵︎Update",)
    Trailblazer::Endpoint::Runtime.({params: {}, seq: []}, adapter: action_adapter_with_model, default_matcher: default_matcher, matcher_context: self, flow_options: flow_options, &matcher_block)
    assert_equal @render, %(404 not found: )

# Update is invalid
    flow_options = original_flow_options.merge(event_label: "☝ ⏵︎Update",)
    Trailblazer::Endpoint::Runtime.({params: {id: 1}, seq: [], update: false}, adapter: action_adapter_with_model, default_matcher: default_matcher, matcher_context: self, flow_options: flow_options, &matcher_block)
    assert_equal @render, %(failed: #<struct Minitest::Spec::Posting id=1, state="⏸︎ Update [00u]">)


# {flow_options} is passed correctly through the entire run.
    flow_options = original_flow_options.merge(event_label: "☝ ⏵︎Update",)
    signal, (ctx, flow_options) = Trailblazer::Endpoint::Runtime.({params: {id: 1}, seq: []}, adapter: action_adapter_with_model, default_matcher: default_matcher, matcher_context: self, flow_options: flow_options, &matcher_block)
    assert_equal flow_options[:event_label], "☝ ⏵︎Update"

    # advance "☝ ⏵︎Create" do |ctx|

    # end.Or() do |ctx|
  end
end
