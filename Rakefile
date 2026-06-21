# frozen_string_literal: true

require "rubocop/rake_task"

RuboCop::RakeTask.new

namespace :rbs do
  desc "`rbs collection install` and `git commit`"
  task :install do
    sh "rbs collection install"
    sh "git add rbs_collection.lock.yaml"
    sh "git commit -m 'rbs collection install' || true"
  end

  desc "Generate sig files from rbs-inline"
  task :generate_sig do
    sh "rbs-inline src/ --output=sig/generated"
  end

  desc "Check rbs"
  task check: :generate_sig do
    sh "rbs validate"
    sh "steep check"
  end
end

desc "Run all static analysis (RuboCop, Steep)"
task lint: [:rubocop, "rbs:check"]

task default: :lint
