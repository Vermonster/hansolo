module Hansolo::Providers::AWS
  module DataBags
    def data_bags
      objects = bucket.objects.with_prefix(Hansolo.app).to_a
      objects.map do |o|
        key = o.key.chomp('.json').sub("#{Hansolo.app}/", '')
        [key, o.read]
      end
    end

    def item_key
      @item_key ||= "#{Hansolo.app}/#{bag}/#{item}.json"
    end

    def item_content
      bucket.objects[item_key].read
    rescue AWS::S3::Errors::NoSuchKey
      "{}"
    end

    def write_to_storage(content)
      bucket.objects[item_key].write(content)
    end
  end
end
