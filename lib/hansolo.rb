require 'net/ssh'
require 'json'
require 'aws-sdk'

module Hansolo
  class Cli
    attr_accessor :keydir, :urls, :runlist, :s3conn, :app, :stage, :aws_bucket_name, :aws_data_bag_keys

    def initialize(args={})
      @keydir                 = args[:keydir]
      @urls                   = args[:urls]
      @runlist                = args[:runlist]
      @app                    = args[:app]
      @stage                  = args[:stage]
      @aws_bucket_name        = args[:aws_bucket_name]
      @aws_data_bag_keys      = args[:aws_data_bag_keys]
      @aws_secret_access_key  = args[:aws_secret_access_key]
      @aws_access_key_id      = args[:aws_access_key_id]

      if (@aws_secret_access_key && @aws_access_key_id && @aws_bucket_name && @aws_data_bag_keys)
        @s3conn = AWS::S3.new(:access_key_id => args[:aws_access_key_id],
                              :secret_access_key => args[:aws_secret_access_key])
      end
    end

    def self.banner
      "Usage: hansolo [OPTS]"
    end

    def self.help
      DATA.read
    end

    def tmpdir
      '/tmp'
    end

    def all!
      vendor_berkshelf!
      rsync_cookbooks!
      rsync_data_bags! if s3conn
      solo!
    end

    def username(url)
      @username ||= Util.parse_url(url)[:username]
    end

    def dest_cookbooks_dir(url)
      File.join("/", "home", username(url), "cookbooks")
    end

    def dest_data_bags_dir(url)
      File.join("/", "home", username(url), "data_bags")
    end

    def local_cookbooks_tmpdir
      File.join(tmpdir, 'cookbooks.working')
    end

    def local_data_bags_tmpdir
      File.join(tmpdir, 'data_bags.working')
    end

    def vendor_berkshelf!
      Util.call_vendor_berkshelf(local_cookbooks_tmpdir)
    end

    def s3_bucket
      s3_bucket = s3conn.buckets[aws_bucket_name]
      if s3_bucket.exists?
        s3_bucket
      else
        s3conn.buckets.create(aws_bucket_name)
      end
    end

    #def s3_key_name
      #"#{app}/#{stage}/environment.json"
    #end

    #def s3_item
      #s3_bucket.objects[s3_key_name]
    #end

    def rsync_cookbooks!
      raise ArgumentError, "missing urls array and keydir"  unless (urls && keydir)
      urls.each do |url|
        opts = Util.parse_url(url).merge(keydir: keydir, sourcedir: local_cookbooks_tmpdir, destdir: dest_cookbooks_dir(url))
        Util.call_rsync(opts)
      end
    end

    def rsync_data_bags!
      # Grab JSON file from S3, and place it into a conventional place
      Util.call("rm -rf #{File.join(local_data_bags_tmpdir, 'app')}")
      Util.call("mkdir -p #{File.join(local_data_bags_tmpdir, 'app')}")

      aws_data_bag_keys.each do |key_name|
        item = s3_bucket.objects[key_name]
        base_key_name = File.basename(key_name)
        File.open(File.join(local_data_bags_tmpdir, 'app', base_key_name), 'w') do |f|
          f.write item.read
        end if item.exists?
      end

      urls.each do |url|
        opts = Util.parse_url(url).merge(keydir: keydir, sourcedir: local_data_bags_tmpdir, destdir: dest_data_bags_dir(url))
        Util.call_rsync(opts)
      end
    end

    def solo!
      raise ArgumentError, "missing urls array and keydir"  unless (urls && keydir)
      urls.each { |url| Util.chef_solo(Util.parse_url(url).merge(keydir: keydir, cookbooks_dir: dest_cookbooks_dir(url), data_bags_dir: dest_data_bags_dir(url), runlist: runlist)) }
    end
  end

  module Util
    def self.call(cmd)
      puts "* #{cmd}"
      %x{#{cmd}}
    end

    def self.call_vendor_berkshelf(tmpdir)
      call("rm -rf #{tmpdir} && bundle exec berks install --path #{tmpdir}")
    end

    def self.call_rsync(args={})
      cmd = "rsync -av -e 'ssh -l #{args[:username]} #{ssh_options(["-p #{args[:port]}", "-i #{args[:keydir]}"])}' "
      cmd << "#{args[:sourcedir]}/ #{args[:username]}@#{args[:hostname]}:#{args[:destdir]}"
      call cmd
    end

    def self.chef_solo(args={})
      # on remote do:
      # build a solo.rb
      # build a tmp json file with the contents { "run_list": [ "recipe[my_app::default]" ] }
      # chef-solo -c solo.rb -j tmp.json

      Net::SSH.start(args[:hostname], args[:username], :port => args[:port], :keys => [ args[:keydir] ]) do |ssh|
        puts ssh.exec! "echo \"#{solo_rb(args[:tmpdir], args[:cookbooks_dir], args[:data_bags_dir])}\" > /tmp/solo.rb"
        puts ssh.exec! "echo '#{ { :run_list => args[:runlist] }.to_json }' > /tmp/deploy.json"
        ssh.exec! 'PATH="$PATH:/opt/vagrant_ruby/bin" sudo chef-solo -l debug -c /tmp/solo.rb -j /tmp/deploy.json' do |ch, stream, line|
          puts line
        end
      end
    end

    private

    def self.solo_rb(tmpdir, cookbooks_dir, data_bags_dir)
      [
        "file_cache_path '#{tmpdir}'",
        "cookbook_path '#{cookbooks_dir}'",
        "data_bag_path '#{data_bags_dir}'"
      ].join("\n")
    end

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

require "hansolo/version"

__END__
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
