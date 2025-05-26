require 'minitest/test'
module Minitest
  # def self.plugin_retryable_options(opts, options)
  #   opts.on "--myci", "Report results to my CI" do
  #     options[:myci] = true
  #     options[:myci_addr] = get_myci_addr
  #     options[:myci_port] = get_myci_port
  #   end
  # end
  class Test < Runnable
    include Mila::Minitest::Retryable
  end

  def self.plugin_retryable_init(_options)
    puts _options
    # self.include(Mila::Minitest::Retryable)
  end
end
