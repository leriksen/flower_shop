task :clean => 'reports' do
  rm_rf Dir.glob("reports/*")
end

