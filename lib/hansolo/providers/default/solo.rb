module Hansolo::Providers::DefaultBehavior
  module Solo

    def sync_data_bags
      rsync_resource(:data_bags)
    end

    def sync_cookbooks
      rsync_resource(:cookbooks)
    end

    private

    def rsync_resource(resource)
      threads = hosts.map do |host|
        Thread.new { call rsync.command(rsync_params(host, resource)) }
      end

      threads.map(&:join)
    end

    def rsync
      Cocaine::CommandLine.new('rsync', rsync_options)
    end

    def rsync_options
      "--delete -av -e \"#{ssh_options}\" :source :destination"
    end

    def ssh_options
      if !bastion.nil?
        "ssh -A -l :bastion_user #{Hansolo.ssh_options} :bastion_host ssh -l :user #{Hansolo.ssh_options} -p :port"
      else
        "ssh -l :user #{Hansolo.ssh_options} -p :port"
      end
    end

    def rsync_params(host, content)
      params = {
        user: host.user,
        ssh_options: Hansolo.ssh_options,
        port: host.port.to_s,
        source: source(content),
        destination: destination(host, content)
      }

      if !bastion.nil?
        params.merge!(
          bastion_user: bastion.user,
          bastion_port: bastion.port.to_s,
          bastion_host: bastion.host
        )
      end

      params
    end

    def source(content)
      "#{Hansolo.send("#{content}_path").join(Hansolo.app)}/"
    end

    def destination(host, content)
      "#{host.user}@#{host.host}:/tmp/#{content}"
    end
  end
end
