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

            instance = instances_by_tag(uri.scheme.to_s, uri.host).first
            raise ArgumentError, "no gateway with #{uri.scheme} #{uri.host} found" if instance.nil?

            URI.parse("ssh://#{uri.user}@#{instance.public_ip_address}:#{uri.port || 22}")
          end
        end

        def hosts
          @hosts ||= begin
            return super unless target.is_a?(Hash)

            target_instances = instances_by_tag(target[:host].to_s, app)

            target_instances.map do |instance|
              ip_address = instance.ip_address || instance.private_ip_address
              URI.parse("ssh://#{target[:user]}@#{ip_address}:#{target[:port] || 22}")
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

        def instances_by_tag(tag, value)
          ec2.instances.tagged(tag).tagged_values(value)
        end
      end
    end
  end
end
