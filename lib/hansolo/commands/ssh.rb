require 'hansolo/commands/base'

module Hansolo::Commands
  class SSH < Base
    def run
      if bastion.nil?
        exec(ssh.command(ssh_params))
      else
        exec(bastion_ssh.command(bastion_params))
      end
    end

    private

    def post_ssh_command
      "#{Hansolo.post_ssh_command}; bash -i"
    end

    def ssh
      Cocaine::CommandLine.new('ssh', ssh_params)
    end

    def ssh_options
      options = ":user@:host #{Hansolo.ssh_options} -p :port"
      options << ' -t :command' if Hansolo.post_ssh_command
      options
    end

    def ssh_params
      @ssh_params ||= begin
        uri = hosts.sample

        {
          user: uri.user,
          host: uri.host,
          port: uri.port.to_s,
          command: post_ssh_command
        }
      end
    end

    def bastion_ssh
      Cocaine::CommandLine.new('ssh', bastion_ssh_options)
    end

    def bastion_ssh_options
      "-A -l :bastion_user #{Hansolo.ssh_options} -p :bastion_port :bastion_host -t \"ssh #{ssh_options}\""
    end

    def bastion_params
      @bastion_params ||= {
        bastion_user: bastion.user,
        bastion_port: bastion.port.to_s,
        bastion_host: bastion.host
      }.merge(ssh_params)
    end
  end
end
