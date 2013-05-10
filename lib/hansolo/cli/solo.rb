require 'hansolo/cli'

module Hansolo
  class Solo < CLI

    def self.banner
      "Usage: hansolo [OPTS]"
    end

    def self.help
      DATA.read
    end

    def run!(opts={})
      if configuration.before_rsync_cookbooks.respond_to?(:call) && !opts[:skip_callbacks]
        instance_eval &configuration.before_rsync_cookbooks
      end
      rsync_cookbooks!

      if configuration.before_rsync_data_bags.respond_to?(:call) && !opts[:skip_callbacks]
        instance_eval &configuration.before_rsync_data_bags
      end
      rsync_data_bags!

      if configuration.before_solo.respond_to?(:call) && !opts[:skip_callbacks]
        instance_eval &configuration.before_solo
      end
      solo!
    end

    def rsync_data_bags!
      threads = []
      urls.each do |url|
        opts = Util.parse_url(url).merge(
          keydir: keydir,
          sourcedir: local_data_bags_dir,
          destdir: Util.dest_data_bags_dir(url),
          gateway: gateway
        )
        threads << Thread.new { Util.call_rsync(opts) }
      end
      threads.each { |t| t.join }
    end

    def rsync_cookbooks!
      threads = []

      urls.each do |url|
        opts = Util.parse_url(url).merge(
          keydir: keydir,
          sourcedir: local_cookbooks_dir,
          destdir: Util.dest_cookbooks_dir(url),
          gateway: gateway
        )

        threads << Thread.new { Util.call_rsync(opts) }
      end
      threads.each { |t| t.join }
    end

    def solo!
      threads = []

      urls.each do |url|
        opts = Util.parse_url(url).merge(
          keydir: keydir,
          tmpdir: '/tmp',
          cookbooks_dir: Util.dest_cookbooks_dir(url),
          data_bags_dir: Util.dest_data_bags_dir(url),
          runlist: runlist,
          gateway: gateway
        )

        threads << Thread.new { Util.chef_solo(opts) }
      end
      threads.each { |t| t.join }
    end
  end
end

__END__
This is a simple cli program to automate deploy using chef-solo and
berkshelf.

Example Usage:

  $ hansolo -s approval -t /tmp/myapp.cookbooks \

      -k /Applications/Vagrant/embedded/gems/gems/vagrant-1.1.4/keys/vagrant \

      -u user@host1:22/path,user@host2:22/path \

      -r apt::default,myapp::deploy

  $ hansolo -s approval -c .hansolo.json

  $ hansolo -s approval

NOTE: You don't need to pass -c if you use the filename .hansolo.json.  Passing -c
will override reading this default.
end
