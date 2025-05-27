module Support
  module Assertions
    def assert_task_defined(task_name)
      assert ::Rake::Task.task_defined?(task_name), "Expected task #{task_name} to be defined"
    end

    def refute_task_defined(task_name)
      refute ::Rake::Task.task_defined?(task_name), "Expected task #{task_name} to not be defined"
    end

     def assert_file_contains(filename, content)
      file_content = File.read(filename)
      assert_includes file_content, content, "Expected #{filename} to contain #{content}"
    end
  end
end