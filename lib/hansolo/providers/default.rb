module Hansolo
  module Providers
    module DefaultBehavior
      def determine_bastion
        @bastion = case Hansolo.gateway
                   when String then URI.parse(Hansolo.gateway)
                   when URI then Hansolo.gateway
                   else raise ArgumentError, 'pass in a String or URI object'
                   end
      end

      def hosts
        @hosts ||= Array(Hansolo.target).map { |target| URI.parse(target) }
      end
    end
  end
end
