if ENV["COVERAGE"]
  SimpleCov.start do
    coverage_dir 'reports/coverage'
    add_filter do |src_file|
      File.basename(src_file.filename) =~ /_spec.rb/
    end
  end
end
