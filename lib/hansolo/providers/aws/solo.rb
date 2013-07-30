module Hansolo::Providers::AWS
  module Solo
    def sync_data_bags
      items = bucket.objects.with_prefix(Hansolo.app)

      command = items.inject([]) do |cmd, object|
        key = object.key.sub("#{Hansolo.app}/", '')
        path = Pathname.new('/tmp/data_bags').join(key)

        cmd << "mkdir -p #{path.dirname}"
        cmd << "echo '#{object.read}' > #{path}"
      end

      command = command.join('; ')

      threads = hosts.map do |host|
        Thread.new do
          ssh = connect(host)
          ssh.exec! command
          ssh.close
        end
      end

      threads.map(&:join)
    end
  end
end
