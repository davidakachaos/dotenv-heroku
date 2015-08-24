require "mkmf"
# Make the MakeMakefile logger write file output to null.
module MakeMakefile::Logging
  @logfile = File::NULL
end

namespace :config do
  task :executable do
    fail "missing heroku executable from the PATH" unless find_executable "heroku"
  end

  desc "push the .env file to heroku config"
  task :push, [:env_file, :appname] => :executable do |t, args|
    args.with_defaults(env_file: ".env")

    # Heroku allows setting env vars in 1 go
    value = File.readlines(args[:env_file]).map(&:strip).join(' ')
    sh "heroku config:set #{value} #{appname ? "--app #{appname}" : nil}"
  end

  desc "pull the config from heroku and write to .env file"
  task :pull, [:env_file, :appname] => :executable do |t, args|
    args.with_defaults(env_file: ".env")
    args.with_defaults(appname: nil)

    remote_config = `heroku config #{appname ? "--app #{appname}" : nil}`
    remote_config or fail "could not fetch remote config"
    remote_config = remote_config.split("\n")
    remote_config.shift # remove the header

    # reformat the lines from
    #   XYZ:    abc
    # to
    #   XYZ=abc
    lines = remote_config.map { |cl|
      cl.split(":").map(&:strip).join("=")
    }

    File.open(args[:env_file], "w") do |f|
      f.puts lines
    end
  end
end

