require 'terminal-table'
require 'hansolo/commands/base'
require 'hansolo/providers/default/data_bags'

module Hansolo
  module Commands
    class DataBag < Base
      include Providers::DefaultBehavior::DataBags

      attr_accessor :bag, :item, :changes

      def run
        changes.nil? ? print : write and print
      end

      def changes=(key_value_pairs)
        @changes = key_value_pairs.inject({}) do |hash, pair|
          key, value = pair.split('=', 2)
          hash[key] = value
          hash
        end
      end

      private

      def read(content = item_content)
        JSON.parse(content)
      end

      def all
        data_bags.map { |key, content| [key, read(content)] }
      end

      def write
        content = read.merge(changes).delete_if { |k, v| v.nil? || v.strip.empty? }
        content['id'] ||= item

        write_to_storage(content.to_json)
      end

      def print
        if !bag.nil? && !item.nil?
          rows = read
          rows.delete('id')

          terminal_table = Terminal::Table.new(rows: rows, headings: ['key', 'value'])
        else
          terminal_table = Terminal::Table.new do |table|
            table.headings = ['key', 'value']
            all.each_with_index do |(bag_and_item, content), i|
              table.add_separator if i != 0

              table.add_row [{ value: ' ', colspan: 2, alignment: :center, border_y: ' ' }]
              table.add_row [{ value: "BAG/ITEM: #{bag_and_item}", colspan: 2, alignment: :center }]

              table.add_separator

              content.delete('id')
              content.each do |k, v|
                table.add_row [k, v]
              end
            end
          end
        end

        STDOUT.puts terminal_table
      end

      def setup_parser
        super

        parser.on('-b', '--data-bag-and-item BAG/ITEM', String, 'The data-bag and data-item, e.g. config/environment') do |option|
          self.bag, self.item = option.split('/')
        end

        parser.on('--set CONFIG', Array, 'Set or unset (with an empty value) key-value pairs, e.g. foo=bar,key=value') do |option|
          self.changes = option
        end
      end
    end
  end
end
