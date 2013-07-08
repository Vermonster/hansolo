require 'aws-sdk'
require 'hansolo'
require 'hansolo/providers/aws/data_bags'
require 'hansolo/providers/aws/discovery'
require 'hansolo/providers/aws/solo'

module Hansolo
  class << self
    attr_accessor :aws_access_key_id, :aws_secret_access_key
  end

  def self.aws_credentials
    @aws_credentials ||= {
      access_key_id: aws_access_key_id,
      secret_access_key: aws_secret_access_key
    }
  end

  class Commands::Base
    include Providers::AWS::Discovery
  end

  class Commands::DataBag
    include Providers::AWS::DataBags
  end

  class Commands::Solo
    include Providers::AWS::Solo
  end
end
