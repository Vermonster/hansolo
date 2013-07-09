module Hansolo::Providers::DefaultBehavior
  module DataBags
    # Key-value pairs of the name of the data bag item to the item's content.
    # @return [Hash]
    def data_bags
      @data_bags ||= Dir[Hansolo.data_bags_path.join('*', '**')].map { |path| [path.chomp('.json'), load_content(path)] }
    end

    # Path to the
    def item_path
      Hansolo.data_bags_path.join(bag, "#{item}.json")
    end

    def load_content(path)
      File.read(path)
    end

    def item_content
      load_content(item_path)
    rescue
      '{}'
    end

    def write_to_storage(content)
      FileUtils.mkdir_p(item_path.dirname)
      File.open(item_path, 'w') { |f| f.write content }
    end
  end
end
