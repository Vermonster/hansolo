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

    def shell_command
      if post_ssh_command
        "#{post_ssh_command}; bash -i"
      else
        "bash -i"
      end
    end

    def ssh
      Cocaine::CommandLine.new('ssh', ssh_params)
    end

    def ssh_arguments
      options = ":user@:host #{ssh_options} -p :port"
      options << ' -t :command'
      options
    end

    def ssh_params
      @ssh_params ||= begin
        uri = hosts.sample

        {
          user: uri.user,
          host: uri.host,
          port: uri.port.to_s,
          command: shell_command
        }
      end
    end

    def bastion_ssh
      Cocaine::CommandLine.new('ssh', bastion_ssh_arguments)
    end

    def bastion_ssh_arguments
      "-A -l :bastion_user #{ssh_options} -p :bastion_port :bastion_host -t \"ssh #{ssh_arguments}\""
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
