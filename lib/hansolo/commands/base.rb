require 'optparse'
require 'cocaine'
require 'net/ssh'
require 'net/ssh/gateway'
require 'hansolo'
require 'hansolo/providers/default'

module Hansolo
  module Commands
    class Base
      include Providers::DefaultBehavior

      attr_reader :bastion

      def self.run(arguments)
        new(arguments).run
      end

      def initialize(arguments)
        load_hanfile!

        setup_parser
        parser.parse!(arguments)

        determine_bastion
      end

      def run
        raise NotImplementedError
      end

      def parser
        @parser ||= OptionParser.new
      end

      private

      def exec(command)
        Hansolo.logger.debug(command)
        Kernel.exec(command)
      end

      def call(command)
        Hansolo.logger.debug(command)
        %x{#{command}}
      end

      def load_hanfile!
        load hanfile_path if File.exists?(hanfile_path)
      end

      def hanfile_path
        @hanfile_path ||= File.expand_path('Hanfile')
      end

      def setup_parser
        parser.on( '-h', '--help', 'display this screen' ) do
          puts parser
          exit
        end

        parser.on( '-t', '--target a,b,c', Array, "comma-sep list of urls, e.g.: user@host:port/dest/path") do |option|
          Hansolo.target = option
        end

        parser.on( '-a', '--app s', String, "the application name") do |option|
          Hansolo.app = option
        end
      end
    end
  end
end
