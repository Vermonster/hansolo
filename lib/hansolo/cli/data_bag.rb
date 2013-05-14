require 'hansolo/cli'

module Hansolo
  class DataBag < CLI
    attr_accessor :data_bag, :data_bag_item

    def initialize(args={})
      super
      if args[:data_bag_and_data_item]
        ( @data_bag, @data_bag_item ) = args[:data_bag_and_data_item].split('/')
      end
    end

    def self.data_bag_filename(configuration, data_bag, data_bag_item)
      File.expand_path(File.join(configuration.local_data_bags_dir, data_bag, "#{data_bag_item}.json"))
    end

    def data_bag_filename
      self.class.data_bag_filename(configuration, data_bag, data_bag_item)
    end

    def self.read_data_bag(data_bag_filename)
      JSON.parse(File.read(data_bag_filename)) if File.exists?(data_bag_filename)
    end

    def read
      if configuration.before_data_bags_read.respond_to?(:call)
        instance_eval &configuration.before_data_bags_read
        Util.check_exit_status
      end
      self.class.read_data_bag(data_bag_filename)
    end

    def read_all
      if configuration.before_data_bags_read.respond_to?(:call)
        instance_eval &configuration.before_data_bags_read
        Util.check_exit_status
      end

      bags_data = {}
      Dir["#{configuration.local_data_bags_dir}/*/**"].each do |filename|
        next if File.directory?(File.expand_path(filename))
        key = filename.gsub(/^#{configuration.local_data_bags_dir}\//, '')
        key.gsub!(/\.json$/,'')
        bags_data[key]  = JSON.parse(File.read(File.expand_path(filename)))
      end
      bags_data
    end

    def run!(args={})
      Hansolo::Solo.new(attributes.merge(args)).run!(skip_callbacks: true)
    end

    def write_data_bag!(new_vars)
      content = self.class.read_data_bag(data_bag_filename) || {}
      new_vars.each_pair do |k,v|
        if v == '' || v.nil?
          content.delete(k)
        else
          content[k] = v
        end
      end

      # The only requirement for a data-bag is to have convention 'id' equal to the name
      content['id'] ||= data_bag_item

      FileUtils.mkdir_p(data_bag_filename.gsub(/\/[^\/]*$/, '/'))
      puts "Made #{data_bag_filename.gsub(/\/[^\/]*$/, '/')}"

      File.open(data_bag_filename, 'w') do |f|
        f.write content.to_json
      end

      if configuration.after_data_bags_write.respond_to?(:call)
        instance_eval &configuration.after_data_bags_write
      end
    end
  end
end
