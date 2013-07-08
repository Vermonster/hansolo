require 'logger'
require "hansolo/version"

module Hansolo
  class << self
    attr_accessor :keydir,
                  :gateway,
                  :app,
                  :target,
                  :runlist,
                  :cookbooks_path,
                  :data_bags_path,
                  :before_rsync_cookbooks,
                  :before_rsync_data_bags,
                  :before_solo,
                  :before_data_bags_read,
                  :after_data_bags_write,
                  :post_ssh_command,
                  :librarian,
                  :ssh_options
  end

  LOGGER = Logger.new(STDOUT)
  LOGGER.formatter = proc do |severity, datetime, progname, msg|
    "* #{msg}\n"
  end

  def self.configure
    yield self

    self.cookbooks_path ||= Pathname.new('tmp/cookbooks')
    self.data_bags_path ||= Pathname.new('tmp/data_bags')
    self.ssh_options    ||= '-q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'
  end

  def self.logger
    LOGGER
  end


  end
end
