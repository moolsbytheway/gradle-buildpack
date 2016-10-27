require 'rspec/core'
require 'hatchet'
require 'fileutils'
require 'hatchet'
require 'rspec/retry'
require 'date'

ENV['RACK_ENV'] = 'test'

RSpec.configure do |config|
  config.filter_run focused: true unless ENV['IS_RUNNING_ON_TRAVIS']
  config.run_all_when_everything_filtered = true
  config.alias_example_to :fit, focused: true
  config.full_backtrace      = true
  config.verbose_retry       = true # show retry status in spec process
  config.default_retry_count = 2 if ENV['IS_RUNNING_ON_TRAVIS'] # retry all tests that fail again

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  #config.mock_with :none
end

def git_repo
  "https://github.com/Scalingo/gradle-buildpack.git"
end

def init_app(app)
  app.setup!
  unless ENV['JVM_COMMON_BUILDPACK'].nil? or ENV['JVM_COMMON_BUILDPACK'].empty?
    app.set_config("JVM_COMMON_BUILDPACK" => ENV['JVM_COMMON_BUILDPACK'])
    expect(app.get_config['JVM_COMMON_BUILDPACK']).to eq(ENV['JVM_COMMON_BUILDPACK'])
  end
end

def add_database(app, scalingo)
  Hatchet::RETRIES.times.retry do
    scalingo.post_addon(app.name, 'scalingo-postgresql')
    _, value = scalingo.get_config_vars(app.name).body.detect {|key, value| key.match(/SCALINGO_POSTGRESQL_[A-Z]+_URL/) }
    scalingo.put_config_vars(app.name, 'DATABASE_URL' => value)
  end
end

def successful_body(app, options = {})
  retry_limit = options[:retry_limit] || 50
  path = options[:path] ? "/#{options[:path]}" : ''
  Excon.get("http://#{app.name}.herokuapp.com#{path}", :idempotent => true, :expects => 200, :retry_limit => retry_limit).body
end

def create_file_with_size_in(size, dir)
  name = File.join(dir, SecureRandom.hex(16))
  File.open(name, 'w') {|f| f.print([ 1 ].pack("C") * size) }
  Pathname.new name
end

def set_java_version(d, v)
  Dir.chdir(d) do
    File.open('system.properties', 'w') do |f|
      f.puts "java.runtime.version=#{v}"
    end
    `git add system.properties`
    `git commit -am "setting jdk version"`
  end
end

def set_gradle_versions(gradle_version)
  propsFile = "gradle/wrapper/gradle-wrapper.properties"
  File.open(propsFile, 'w') do |f|
    f.puts <<-EOF
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-#{gradle_version}-bin.zip
EOF
  end
  `git add #{propsFile}`
  `git commit -m "setting gradle version"`
end

ReplRunner.register_commands(:console)  do |config|
  config.terminate_command "exit"          # the command you use to end the 'rails console'
  config.startup_timeout 60                # seconds to boot
  config.return_char "\n"                  # the character that submits the command
  config.sync_stdout "STDOUT.sync = true"  # force REPL to not buffer standard out
end
