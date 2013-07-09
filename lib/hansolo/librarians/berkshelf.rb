module Hansolo::Librarians
  module Berkshelf
    module_function

    def install!
      directory = Pathname.new("tmp/cookbooks/#{Hansolo.app}")
      FileUtils.mkdir_p(directory)

      files = Dir[directory.join('*')]
      FileUtils.rm_rf(files)

      system("berks install --path #{directory}")
    end
  end
end
