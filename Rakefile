# Rakefile
# --------
# Run 'rake lint' to lint Puppet files. Requires 'puppet-lint'.
#
require 'puppet-lint/tasks/puppet-lint'

# Work around bug in puppet-lint configuration
# https://github.com/rodjek/puppet-lint/issues/331
Rake::Task[:lint].clear
PuppetLint::RakeTask.new(:lint) do |config|
  gitmodules = File.expand_path('../.gitmodules', __FILE__)
  config.ignore_paths = IO.readlines(gitmodules).grep(/\s*path\s*=\s*(\S+)/) { "#{$1}/**/*.pp" }
  config.disable_checks = ['80chars', 'class_parameter_defaults', 'autoloader_layout']
  config.log_format = '%{path}:%{line} %{KIND} %{message} (%{check})'
end

task :default => [:lint]
