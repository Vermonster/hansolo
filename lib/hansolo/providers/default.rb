module Hansolo
  module Providers
    module DefaultBehavior
      # Sets {Hansolo::Commands::Base#bastion}
      # @return [URI, NilClass]
      def determine_bastion
        @bastion = case gateway
                   when String then URI.parse(gateway)
                   when URI then gateway
                   else raise ArgumentError, 'pass in a String or URI object'
                   end
      end

      # Builds an array of `URI` instances representing target nodes
      # @return [Array<URI>]
      def hosts
        @hosts ||= Array(target).map { |target| URI.parse(target) }
      end
    end
  end
end
