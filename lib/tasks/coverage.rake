desc "Run RSpec with SimpleCov; report at coverage/index.html"
task :coverage do
  ENV["COVERAGE"] = "1"
  sh "bundle exec rspec"
end
