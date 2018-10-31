module Bosh::Director
  module DeploymentPlan
    class DeploymentFeatures
      attr_reader :use_dns_addresses
      attr_reader :use_link_dns_names
      attr_reader :use_short_dns_addresses
      attr_reader :randomize_az_placement
      attr_reader :converge_variables

      def initialize(
        use_dns_addresses = nil,
        use_short_dns_addresses = nil,
        randomize_az_placement = nil,
        converge_variables = false,
        use_link_dns_names = false
      )
        @use_dns_addresses = use_dns_addresses
        @use_link_dns_names = use_link_dns_names
        @use_short_dns_addresses = use_short_dns_addresses
        @randomize_az_placement = randomize_az_placement
        @converge_variables = converge_variables
      end
    end
  end
end
