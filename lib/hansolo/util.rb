module Hansolo
  module Util
    def self.call(cmd)
      puts "* #{cmd}"
      %x{#{cmd}}
    end

    def self.exec(cmd)
      puts "* #{cmd}"
      Kernel.exec(cmd)
    end

    def self.dest_cookbooks_dir(url)
      File.join("/", "home", Util.username(url), "cookbooks")
    end

    def self.dest_data_bags_dir(url)
      File.join("/", "home", Util.username(url), "data_bags")
    end

    def self.call_vendor_berkshelf(tmpdir)
      call("rm -rf #{tmpdir} && bundle exec berks install --path #{tmpdir}")
    end

    def self.call_ssh(args={})
      cmd = "#{gateway_cmd(args[:gateway])} -t 'ssh #{args[:username]}@#{args[:hostname]} #{ssh_options(["-p #{args[:port]}"])}"
      cmd << " -t \"#{args[:post_ssh_cmd]}; bash -i\"" if args[:post_ssh_cmd]
      cmd << "'"
      exec cmd
    end

    def self.call_rsync(args={})
      cmd = "rsync --delete -av -e '#{gateway_cmd(args[:gateway])} ssh -l #{args[:username]} #{ssh_options(["-p #{args[:port]}"])}' "
      cmd << "#{args[:sourcedir]}/ #{args[:username]}@#{args[:hostname]}:#{args[:destdir]}"
      call cmd
    end

    def self.gateway_cmd(gateway_url=nil)
      return unless gateway_url

      gateway_parts = parse_url(gateway_url)
      "ssh -A -l #{gateway_parts[:username]} -X #{ssh_options(["-p #{gateway_parts[:port]}"])} #{gateway_parts[:hostname]}"
    end

    def self.chef_solo(args={})
      # on remote do:
      # build a solo.rb
      # build a tmp json file with the contents { "run_list": [ "recipe[my_app::default]" ] }
      # chef-solo -c solo.rb -j tmp.json

      if args[:gateway]
        require 'net/ssh/gateway'

        gateway_params = parse_url(args[:gateway])
        gateway = Net::SSH::Gateway.new(gateway_params[:hostname],
                                        gateway_params[:username],
                                        { port: gateway_params[:port] })

        gateway.ssh(args[:hostname], args[:username], :port => args[:port]) do |ssh|
          chef_solo_ssh_cmds(ssh, args)
        end
      else
        Net::SSH.start(args[:hostname], args[:username], :port => args[:port]) do |ssh|
          chef_solo_ssh_cmds(ssh, args)
        end
      end
    end

    def self.chef_solo_ssh_cmds(ssh, args={})
      puts ssh.exec! "echo \"#{solo_rb(args[:tmpdir], args[:cookbooks_dir], args[:data_bags_dir])}\" > /tmp/solo.rb"
      puts ssh.exec! "echo '#{ { :run_list => args[:runlist] }.to_json }' > /tmp/deploy.json"
      ssh.exec! 'PATH="$PATH:/opt/vagrant_ruby/bin" sudo chef-solo -c /tmp/solo.rb -j /tmp/deploy.json' do |ch, stream, line|
        puts line
      end
    end

    def self.username(url)
      parse_url(url)[:username]
    end

    def self.check_exit_status
      exit_status = $?.respond_to?(:exitstatus) ? $?.existatus : 0
      raise StandardError, "Command failed!" if exist_status != 0
    end

    private

    def self.solo_rb(tmpdir, cookbooks_dir, data_bags_dir)
      [
        "file_cache_path '#{tmpdir}'",
        "cookbook_path '#{cookbooks_dir}'",
        "data_bag_path '#{data_bags_dir}'"
      ].join("\n")
    end

    # TODO: Use URI.parse, no reason to reinvent this!
    def self.parse_url(url)
      if (url =~ /^([^\@]*)@([^:]*):([0-9]*)$/)
        return { username: $1, hostname: $2, port: $3.to_i }
      else
        raise ArgumentError, "Unable to parse `#{url}', should be in form `user@host:port'"
      end
    end

    def self.ssh_options(opts=[])
      (
        [
          "-q",
          "-o StrictHostKeyChecking=no",
          "-o UserKnownHostsFile=/dev/null"
      ] + opts
      ).join(' ')
    end
  end
end
