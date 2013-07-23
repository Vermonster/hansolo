require 'optparse'
require 'cocaine'
require 'net/ssh'
require 'net/ssh/gateway'
require 'hansolo'
require 'hansolo/providers/default'

module Hansolo
  module Commands
    # Responsible for taking in command line options and reading in `Hanfile`.
    # Any unique command line options should be added in a subclass. Provides
    # minimal helpers for executing commands.
    class Base
      include Providers::DefaultBehavior

      # @!attribute [r] bastion
      #   @return [URI] attributes of the bastion server
      attr_reader :bastion

      attr_writer *ATTRIBUTES

      ATTRIBUTES.each do |attribute|
        define_method attribute do
          if instance_variable_defined?("@#{attribute}")
            instance_variable_get("@#{attribute}")
          else
            Hansolo.send(attribute)
          end
        end
      end

      # Run the command
      # @see {#run}
      def self.run(arguments)
        new(arguments).run
      end

      # Sets up command
      #
      # * Loads the `Hanfile`
      # * Parses command line arguments
      # * Determines the {#bastion} if {Hansolo.gateway} is specified
      def initialize(arguments)
        load_hanfile!

        setup_parser
        parser.parse!(arguments)

        determine_bastion if gateway
      end

      # Public interface to the command to be implemented in a subclass.
      def run
        raise NotImplementedError
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

      def parser
        @parser ||= OptionParser.new
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
          self.target = option
        end

        parser.on( '-a', '--app s', String, "the application name") do |option|
          self.app = option
        end
      end
    end
  end
end
