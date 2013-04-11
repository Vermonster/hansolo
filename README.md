# Hansolo

NOTE: This is alpha code.

Cli tool to automate berkshelf and chef-solo deployment

## Installation

Add this line to your application's Gemfile:

    gem 'hansolo'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hansolo

## Example configuration file

    {
      "urls": [ "vagrant@localhost:2222" ],
      "runlist": [ "my_app::deploy" ],
      "app":"my_app",
      "keydir":"/Applications/Vagrant/embedded/gems/gems/vagrant-1.1.4/keys/vagrant",
      "aws_access_key_id":"AAAAAAAAAAAAAAAAAAAA",
      "aws_secret_access_key":"1111111111111111111111111111111111111111",
      "aws_bucket_name":"acme-data_bags",
      "aws_data_bag_keys":["my_app/stage/environment.json"]
    }

## Usage

See the binary:

    $ hansolo -h


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
