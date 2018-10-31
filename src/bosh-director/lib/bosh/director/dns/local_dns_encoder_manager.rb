module Bosh::Director
  class LocalDnsEncoderManager
    def self.persist_az_names(azs)
      azs.each do |azname|
        encode_az(azname)
      end
    end

    def self.persist_network_names(networks)
      networks.each do |networkname|
        encode_network(networkname)
      end
    end

    def self.create_dns_encoder(use_short_dns_names = false)
      az_hash = Models::LocalDnsEncodedAz.as_hash(:name, :id)

      service_groups = {}
      dns_groups_table_name = Bosh::Director::Models::LocalDnsEncodedGroup.table_name
      Bosh::Director::Models::LocalDnsEncodedGroup
        .inner_join(:deployments, Sequel.qualify(dns_groups_table_name, 'deployment_id') => Sequel.qualify('deployments', 'id'))
        .select(
          Sequel.expr(Sequel.qualify(dns_groups_table_name, 'id')).as(:id),
          Sequel.expr(Sequel.qualify(dns_groups_table_name, 'name')).as(:name),
          Sequel.expr(Sequel.qualify(dns_groups_table_name, 'type')).as(:type),
          Sequel.expr(Sequel.qualify('deployments', 'name')).as(:deployment_name),
        ).all.each do |join_row|
        service_groups[{
          group_type: join_row[:type],
          group_name: join_row[:name],
          deployment: join_row[:deployment_name],
        }] = join_row[:id].to_s
      end

      Bosh::Director::DnsEncoder.new(service_groups, az_hash, use_short_dns_names)
    end

    def self.new_encoder_with_updated_index(plan)
      persist_az_names(plan.availability_zones.map(&:name))
      persist_network_names(plan.networks.map(&:name))
      persist_service_groups(plan)
      create_dns_encoder(plan.use_short_dns_addresses?)
    end

    class << self
      private

      # rubocop:disable Lint/HandleExceptions
      def with_skip_dupes
        yield
      rescue Sequel::UniqueConstraintViolation => _
      end
      # rubocop:enable Lint/HandleExceptions

      def encode_az(name)
        with_skip_dupes { Models::LocalDnsEncodedAz.find_or_create(name: name) }
      end

      def encode_instance_group(name, deployment_model)
        with_skip_dupes do
          Models::LocalDnsEncodedGroup.find_or_create(
            type: Models::LocalDnsEncodedGroup::Types::INSTANCE_GROUP,
            name: name,
            deployment: deployment_model,
          )
        end
      end

      def encode_link_provider(name, type, deployment_model)
        with_skip_dupes do
          Models::LocalDnsEncodedGroup.find_or_create(
            type: Models::LocalDnsEncodedGroup::Types::LINK,
            name: "#{name}-#{type}",
            deployment: deployment_model,
          )
        end
      end

      def encode_network(name)
        with_skip_dupes { Models::LocalDnsEncodedNetwork.find_or_create(name: name) }
      end

      def persist_service_groups(plan)
        deployment_model = plan.model

        plan.instance_groups.each do |ig|
          encode_instance_group(ig.name, deployment_model)
        end

        plan.links_manager.get_link_providers_for_deployment(deployment_model).each do |provider|
          encode_link_provider(provider.name, provider.type, deployment_model)
        end
      end
    end
  end
end
