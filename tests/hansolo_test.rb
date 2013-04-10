$: << File.expand_path(File.join(__FILE__, '..', '..', 'lib'))

require 'minitest/autorun'
require 'mocha/setup'

require 'hansolo'

describe Hansolo do

  describe Hansolo::Cli do

    describe "#vendor_berkshelf!" do
      before { @cli = Hansolo::Cli.new }

      it "should shell berkshelf command" do
        Hansolo::Util.expects(:call).with("rm -rf /tmp/cookbooks.working && bundle exec berks install --path /tmp/cookbooks.working")
        @cli.vendor_berkshelf!
      end
    end

    describe "#rsync!" do
      before { @cli = Hansolo::Cli.new(keydir: '/keys', urls: [ 'user@host:22']) }

      it "should shell rsync command" do
        Hansolo::Util.expects(:call).with("rsync -av -e 'ssh -l user -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 22 -i /keys' /tmp/cookbooks.working/ user@host:/home/user/cookbooks")
        @cli.rsync_cookbooks!
      end
    end

  end

  describe Hansolo::Util do

    describe ".parse_url" do
      it "parses" do
        Hansolo::Util.parse_url('user@host:123').must_equal({ username: 'user', hostname: 'host', port: 123 })
      end

      it "doesn't parse" do
        lambda{ Hansolo::Util.parse_url('foob') }.must_raise ArgumentError
      end
    end
  end

end
