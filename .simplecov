if ENV["COVERAGE"]
  SimpleCov.start do
    coverage_dir 'reports/coverage'
    add_filter "/spec/"
    add_filter "/tasks/"
  end
end
