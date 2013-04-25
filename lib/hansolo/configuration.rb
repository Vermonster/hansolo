module Hansolo
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  class Configuration
    attr_accessor :keydir,
      :urls,
      :app,
      :gateway,
      :runlist,
      :local_cookbooks_dir,
      :local_data_bags_dir,
      :before_rsync_cookbooks,
      :before_rsync_data_bags,
      :before_solo,
      :before_data_bags_read,
      :after_data_bags_write

    def initialize
      @local_cookbooks_dir = File.join('tmp', 'cookbooks')
      @local_data_bags_dir = File.join('tmp', 'data_bags')
    end
  end
end
