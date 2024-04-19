require "test_helper"

class CollaborationTest < Minitest::Spec
  it "Workflow.Collaboration()" do
    schema, _ = build_schema()

    lanes = schema.to_h[:lanes]

    lifecycle, ui, editor = lanes.to_h.keys

    assert_equal lanes.class, Trailblazer::Workflow::Introspect::Lanes
    assert_equal lanes.to_h, {
      lifecycle => {:label=>"lifecycle", :icon=>"⛾", :name=>"posting", :activity=>lifecycle, :json_id=>"⛾.lifecycle.posting"},
      ui => {:label=>"UI", :icon=>"☝", :name=>"blogger", :activity=>ui, json_id: "☝.UI.blogger"},
      editor => {:label=>"editor", :icon=>"☑", :name=>"reviewer", :activity=>editor, :json_id=>"☑.editor.reviewer"},
    }

    # TODO: test other {#to_h} components.
  end
end
