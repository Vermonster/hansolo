module Hansolo::Providers::AWS
  module DataBags
    def data_bags
      bucket.objects.select { |o| o.key =~ /\.json$/ }.map { |object| [object.key.chomp('.json'), object.read] }
    end

    def item_key
      @item_key ||= "#{bag}/#{item}.json"
    end

    def item_content
      bucket.objects[item_key].read
    end

    def write_to_storage(content)
      bucket.objects[item_key].write(content)
    end
  end
end
