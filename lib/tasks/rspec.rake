directory "reports/coverage"

begin
  require 'rspec/core/rake_task'
rescue LoadError
  fail "Unable to load RSpec rake tasks - have you run via 'bundle exec rake spec' ?"
rescue exception
  fail "Cannot run rspec rake task - #{exception.message}"
end

desc "test the internal libs"
RSpec::Core::RakeTask.new(:spec => 'reports')
