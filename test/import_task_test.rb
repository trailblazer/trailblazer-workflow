require "test_helper"
require "trailblazer/workflow/task/import" # FIXME.

class ImportTaskTest < Minitest::Spec
  after do
    `rm /tmp/79d163.json`
  end

  let(:api_key) { "tpka_909ae987_c834_43e4_9869_2eefd2aa9bcf" }
  let(:trailblazer_pro_host) { "https://testbackend-pro.trb.to" } # NOTE: it's a bit clumsy to share PRO testing knowledge across several gems, but this code belongs here.

  let(:session_static_options) do
    {
      api_key: api_key,
      trailblazer_pro_host: trailblazer_pro_host,
      firebase_refresh_url: "https://securetoken.googleapis.com/v1/token?key=AIzaSyDVZOdUrI6wOji774hGU0yY_cQw9OAVwzs",
    }
  end # FIXME: do we need this?


  it "Import retrieves editor JSON file" do
  #@ Uninitialized sigin
    initial_session = Trailblazer::Pro::Session::Uninitialized.new(trailblazer_pro_host: trailblazer_pro_host, api_key: api_key)

    signal, (ctx, _) = Trailblazer::Developer.wtf?(Trailblazer::Workflow::Task::Import, [{
      session: initial_session,
      diagram_slug: "79d163",
      target_filename: "/tmp/79d163.json",
    }, {}])

    assert_equal signal.to_h[:semantic], :success
    assert_equal File.read("/tmp/79d163.json").size, 4635
  end

  it "Import shows HTTP error" do
  #@ Uninitialized sigin
    initial_session = Trailblazer::Pro::Session::Uninitialized.new(trailblazer_pro_host: trailblazer_pro_host, api_key: "api_key-XXX")

    signal = nil
    # output, _ = capture_io do
      signal, (ctx, _) = Trailblazer::Developer.wtf?(Trailblazer::Workflow::Task::Import, [{
        session: initial_session,
        diagram_slug: "79d163",
        target_filename: "/tmp/79d163.json",
      }, {}])
    # end

    assert_equal signal.to_h[:semantic], :failure
    assert_equal File.exist?("/tmp/79d163.json"), false
    # assert_equal output.split("\n").last, %(asdf)
    assert_equal ctx[:error_message], %(Custom token couldn't be retrieved. HTTP status: 401)
  end
end
