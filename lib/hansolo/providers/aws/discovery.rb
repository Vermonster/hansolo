module Hansolo
  module Providers
    module AWS
      module Discovery
        def ec2
          @ec2 ||= ::AWS::EC2.new(Hansolo.aws_credentials)
        end

        def s3
          @s3 ||= ::AWS::S3.new(Hansolo.aws_credentials)
        end

        def determine_bastion
          @bastion = begin
            uri = super

            return uri if uri.scheme == 'ssh'

            ip_address = instance_ip_addresses_by_tag(uri.scheme.to_s, uri.host).first
            raise ArgumentError, "no gateway with #{uri.scheme} #{uri.host} found" if ip_address.nil?

            URI.parse("ssh://#{uri.user}@#{ip_address}:#{uri.port || 22}")
          end
        end

        def hosts
          @hosts ||= begin
            target = Hansolo.target

            if target.is_a?(Hash)
              target_instances = instance_ip_addresses_by_tag(target[:host].to_s, Hansolo.app)

              target_instances.map do |ip_address|
                URI.parse("ssh://#{target[:user]}@#{ip_address}:#{target[:port] || 22}")
              end
            else
              target.inject([]) do |uris, uri|
                uri = URI.parse(uri)

                if uri.scheme == 'ssh'
                  uris << uri
                else
                  ip_addresses = instance_ip_addresses_by_tag(uri.scheme.to_s, uri.host)

                  uris += ip_addresses.map do |ip_address|
                    URI.parse("ssh://#{uri.user}@#{ip_address}:#{uri.port || 22}")
                  end
                end
              end
            end
          end
        end

        private

        def bucket
          @bucket ||= begin
            name = Hansolo.bucket_name

            bucket = s3.buckets[name]
            bucket = s3.buckets.create(name) unless bucket.exists?
            bucket
          end
        end

        def instance_ip_addresses_by_tag(tag, value)
          instances = ec2.instances.tagged(tag).tagged_values(value).to_a
          instances.select! { |instance| instance.status != :terminated }
          instances.map! { |instance| instance.ip_address || instance.private_ip_address }
        end
      end
    end
  end
end
