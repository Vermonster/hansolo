require 'hansolo/cli'

module Hansolo
  class SSH < CLI
    attr_accessor :post_ssh_cmd

    def initialize(args={})
      super
      @post_ssh_cmd = args[:post_ssh_cmd] || configuration.post_ssh_cmd
    end

    def ssh!
      opts = Util.parse_url(urls.sample).merge(
        gateway: gateway,
        post_ssh_cmd: post_ssh_cmd
      )

      Util.call_ssh(opts)
    end
  end
end
