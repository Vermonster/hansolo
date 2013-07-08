require 'hansolo/commands/base'
require 'hansolo/providers/default/solo'

module Hansolo
  module Commands
    class Solo < Base
      include Providers::DefaultBehavior::Solo

      def run
        sync_data_bags

        Hansolo.librarian.install!
        sync_cookbooks

        execute_chef_solo
      end

      def execute_chef_solo
        threads = hosts.map do |host|
          ssh = connect(host)

          Thread.new do
            ssh.exec! generate_manifest.command(manifest: manifest)
            ssh.exec! generate_json.command(json: json)

            ssh.exec! chef_solo do |channel, stream, line|
              puts line
            end

            ssh.close
          end
        end

        threads.map(&:join)
      end

      private

      def chef_solo
        'sudo chef-solo -c /tmp/solo.rb -j /tmp/deploy.json'
      end

      def connect(host)
        if bastion.nil?
          Net::SSH.new(host.host, host.user, port: host.port)
        else
          gateway.ssh(host.host, host.user, port: host.port)
        end
      end

      def generate_manifest
        Cocaine::CommandLine.new('echo', ':manifest > /tmp/solo.rb')
      end

      def generate_json
        Cocaine::CommandLine.new('echo', ':json > /tmp/deploy.json')
      end

      def manifest
        <<-MANIFEST
file_cache_path '/tmp'
cookbook_path '/tmp/cookbooks'
data_bag_path '/tmp/data_bags'
        MANIFEST
      end

      def json
        { :run_list => Hansolo.runlist }.to_json
      end

      def gateway
        @gateway ||= Net::SSH::Gateway.new(bastion.host, bastion.user, port: bastion.port)
      end
    end
  end
end
