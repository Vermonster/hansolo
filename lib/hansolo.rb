require 'net/ssh'
require 'json'

module Hansolo
  class Cli
    attr_accessor :keydir, :urls, :tmpdir, :runlist

    def initialize(args={})
      @keydir = args[:keydir]
      @urls = args[:urls]
      @runlist = args[:runlist]
      @tmpdir = args[:tmpdir] || '/tmp/cookbooks.working/'
      @tmpdir << '/' unless @tmpdir =~ /\/$/
    end

    def self.banner
      "Usage: hansolo [OPTS]"
    end

    def self.help
      <<-HELP
This is a simple cli program to automate deploy using chef-solo and
berkshelf.

If you pass a filename, put in JSON for the configuration.  So in hans.json:

  { "keydir": "/Applications/Vagrant/embedded/gems/gems/vagrant-1.1.4/keys/vagrant" }

Then you can pass to the command as:

  $ hansolo -c hans.json

NOTE: Command-line args trump config settings.

Example Usage:

  $ hansolo -t /tmp/myapp.cookbooks \

      -k /Applications/Vagrant/embedded/gems/gems/vagrant-1.1.4/keys/vagrant \

      -u user@host1:22/path,user@host2:22/path \

      -r apt::default,myapp::deploy

  $ hansolo -c hans.json

      HELP
    end

    def all!
      vendor_berkshelf!
      rsync!
      solo!
    end

    def vendor_berkshelf!
      Util.call_vendor_berkshelf(tmpdir)
    end

    def rsync!
      raise ArgumentError, "missing urls array and keydir"  unless (urls && keydir)
      urls.each { |url| Util.call_rsync(Util.parse_url(url).merge(keydir: keydir, tmpdir: tmpdir)) }
    end

    def solo!
      raise ArgumentError, "missing urls array and keydir"  unless (urls && keydir)
      urls.each { |url| Util.call_chef_solo(Util.parse_url(url).merge(runlist: runlist)) }
    end
  end

  module Util
    def self.call(cmd)
      %x{cmd}
    end

    def self.call_vendor_berkshelf(tmpdir)
      call("bundle exec berks install --path #{tmpdir}")
    end

    def self.call_rsync(args={})
      cmd = "rsync -av -e 'ssh -l #{args[:username]} #{ssh_options(["-p #{args[:port]}", "-i #{args[:keydir]}"])}' "
      cmd << "#{args[:tmpdir]} #{args[:username]}@#{args[:hostname]}:#{args[:destination]}"
      call cmd
    end

    def self.chef_solo(args={})
      # on remote do:
      # build a solo.rb
      # build a tmp json file with the contents { "run_list": [ "recipe[my_app::default]" ] }
      # chef-solo -c solo.rb -j tmp.json

      Net::SSH.start(args[:hostname], args[:username], :port => args[:port], :keys => [ args[:keydir] ]) do |ssh|
        puts ssh.exec! "echo '#{solo_rb(args[:tmpdir], args[:destination])}' > /tmp/solo.rb"
        puts ssh.exec! "echo '#{ { :run_list => args[:run_list] }.to_json }' > /tmp/deploy.json"
        ssh.exec! "sudo chef-solo -l debug -c /tmp/solo.rb -j /tmp/deploy.json" do |ch, stream, line|
          puts line
        end
      end
    end

    private

    def self.solo_rb(tmpdir, cookbookdir)
      [
        "file_cache_path '#{tmpdir}'",
        "cookbook_path '#{cookbookdir}'"
      ].join("\n")
    end

    def self.parse_url(url)
      if (url =~ /^([^\@]*)@([^:]*):([0-9]*)(\/.*)$/)
        return { username: $1, hostname: $2, port: $3.to_i, destination: $4 }
      else
        raise ArgumentError, "Unable to parse `#{url}', should be in form `user@host:port/dest_dir'"
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

require "hansolo/version"
