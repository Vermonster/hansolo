module Hansolo
  class CLI
    @@attr_accessors = [ :keydir, :app, :urls, :runlist, :local_tmp_dir, :local_cookbooks_dir, :local_data_bags_dir, :gateway ]
    attr_accessor *@@attr_accessors

    def configuration
      Hansolo.configuration
    end

    def initialize(args={})
      @keydir               = args[:keydir] || configuration.keydir
      @urls                 = args[:urls] || configuration.urls
      @runlist              = args[:runlist] || configuration.runlist
      @local_cookbooks_dir  = args[:local_cookbooks_dir] || configuration.local_cookbooks_dir
      @local_data_bags_dir  = args[:local_data_bags_dir] || configuration.local_data_bags_dir
      @app                  = args[:app] || configuration.app
      @gateway              = args[:gateway] || configuration.gateway
    end

    def self.banner
      "hansolo-config [OPTS]"
    end

    def attributes
      @@attr_accessors.each.with_object({}) { |attr, h| h[attr] = send(attr) }
    end

  end
end

require 'hansolo/cli/solo'
require 'hansolo/cli/data_bag'
