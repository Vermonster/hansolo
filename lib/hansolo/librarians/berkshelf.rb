module Hansolo::Librarians
  module Berkshelf
    module_function

    def install!

      if Gem.loaded_specs['berkshelf'].version < Gem::Version.new('3')
        directory = Pathname.new("tmp/cookbooks/#{Hansolo.app}")
        FileUtils.mkdir_p(directory)

        files = Dir[directory.join('*')]
        FileUtils.rm_rf(files)

        system("berks install --path #{directory}")
      else
        directory = Pathname.new("tmp/cookbooks/#{Hansolo.app}")
        FileUtils.rm_rf(directory)

        system("berks vendor #{directory}")
      end

    end
  end
end
