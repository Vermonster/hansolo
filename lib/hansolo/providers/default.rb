module Hansolo
  module Providers
    module DefaultBehavior
      # Sets {Hansolo::Commands::Base#bastion}
      # @return [URI, NilClass]
      def determine_bastion
        @bastion = case Hansolo.gateway
                   when String then URI.parse(Hansolo.gateway)
                   when URI then Hansolo.gateway
                   else raise ArgumentError, 'pass in a String or URI object'
                   end
      end

      # Builds an array of `URI` instances representing target nodes
      # @return [Array<URI>]
      def hosts
        @hosts ||= Array(Hansolo.target).map { |target| URI.parse(target) }
      end
    end
  end
end
