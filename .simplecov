SimpleCov.start do
  command_name "Net::IMAP tests"
  enable_coverage :branch
  primary_coverage :branch
  enable_coverage_for_eval

  add_filter "/test/"

  add_group "SASL", %w[lib/net/imap/sasl.rb
                       lib/net/imap/sasl]
  add_group "Parser", %w[lib/net/imap/response_parser.rb
                         lib/net/imap/response_parser]
end
