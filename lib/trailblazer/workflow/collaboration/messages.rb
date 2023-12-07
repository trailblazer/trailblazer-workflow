module Trailblazer
  module Workflow
    class Collaboration
      # A "path" here means: [activity_id, task_id]
      #
      # Return a hash, key is always a throw event (the actual task instance),
      # value the [activity, catch_event] tuple.
      def self.Messages(messages, id_to_lane)
        messages.collect do |throw_path, catch_path|  # [["article moderation", "Event_0odjl3c"], ["<ui> author workflow", "Event_0co8ygx"]]
          # throw
          activity_id, task_id = throw_path
          _, throw_task = find_task_for_ids(activity_id, task_id, id_to_lane)

          # catch
          activity_id, task_id = catch_path
          catch_path = find_task_for_ids(activity_id, task_id, id_to_lane)

          # thrower => [activity, catcher]
          [throw_task, catch_path]
        end
          .to_h
      end

      # Return [activity, task] for ID tuple.
      def self.find_task_for_ids(activity_id, task_id, id_to_lane)
        activity = id_to_lane.fetch(activity_id) # TODO: test exception.

        return activity, Activity::Introspect.Nodes(activity, id: task_id).task
      end
    end
  end
end
