module Hansolo::Providers::AWS
  module Solo
    def sync_data_bags
      threads = hosts.map do |host|
        Thread.new do
          ssh = connect(host)

          command = data_bag_items.inject([]) do |cmd, object|
            path = Pathname.new('/tmp/data_bags').join(object.key)

            cmd << "mkdir -p #{path.dirname}"
            cmd << "echo '#{object.read}' > #{path}"
          end

          ssh.exec! command.join('; ')
          ssh.close
        end
      end

      threads.map(&:join)
    end

    def data_bag_items
      bucket.objects.select { |o| o.key =~ /\.json$/ }
    end
  end
end
