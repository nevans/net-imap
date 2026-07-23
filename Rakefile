# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"
require "rake/clean"

Rake::TestTask.new(:test) do |t|
  t.libs << "test/lib"
  t.ruby_opts << "-rhelper"
  t.test_files = FileList["test/**/test_*.rb"]
end

task :default => :test

desc "Output coverage data report, and error when threshholds aren't met"
task "coverage:report" do
  require "simplecov"
  SimpleCov.collate "coverage/.resultset.json" do
    coverage(:line) do
      minimum           95

      minimum_per_group 98, only: "Config"
      minimum_per_group 97, only: "StringPrep"
      minimum_per_group 97, only: "SASL"
      minimum_per_group 95, only: "Data Types"
      minimum_per_group 94, only: "Parser"
      minimum_per_group 92, only: "Client"

      minimum_per_file  90
      minimum_per_file  87, only: "lib/net/imap/sasl/authenticators.rb"
      minimum_per_file  86, only: "lib/net/imap/config/attr_type_coercion.rb"
      minimum_per_file  84, only: "lib/net/imap/authenticators.rb"
      minimum_per_file  80, only: "lib/net/imap/response_data.rb"
      minimum_per_file  55, only: "lib/net/imap/search_result.rb"
    end

    coverage(:branch) do
      minimum           80

      minimum_per_group 92, only: "Data Types"
      minimum_per_group 87, only: "Config"
      minimum_per_group 83, only: "Client"
      minimum_per_group 81, only: "Parser"
      minimum_per_group 76, only: "SASL"
      minimum_per_group 73, only: "StringPrep"

      minimum_per_file  65
      minimum_per_file  62, only: "lib/net/imap/sasl/scram_authenticator.rb"
      minimum_per_file  50, only: "lib/net/imap/sasl/authenticators.rb"
      minimum_per_file  50, only: "lib/net/imap/config/attr_accessors.rb"
    end

    coverage(:method) do
      minimum            88

      minimum_per_group 100, only: "Config"
      minimum_per_group  92, only: "Data Types"
      minimum_per_group  90, only: "StringPrep"
      minimum_per_group  88, only: "Client"
      minimum_per_group  83, only: "Parser"
      minimum_per_group  82, only: "SASL"

      minimum_per_file   66
      minimum_per_file   64, only: "lib/net/imap/response_parser/parser_utils.rb"
      minimum_per_file   57, only: "lib/net/imap/sasl/authenticators.rb"
      minimum_per_file   50, only: "lib/net/imap/authenticators.rb"
      minimum_per_file   50, only: "lib/net/imap/sasl/anonymous_authenticator.rb"
      minimum_per_file   36, only: "lib/net/imap/sasl/protocol_adapters.rb"
      minimum_per_file   20, only: "lib/net/imap/response_data.rb"
    end
  end
end
