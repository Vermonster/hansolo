# Hansolo

NOTE: This is alpha code.

CLI tool to automate berkshelf and chef-solo deployment

## Installation

Add this line to your application's Gemfile:

    gem 'hansolo'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hansolo

## Usage

`hansolo` provides three command line utilities for managing nodes with `chef-solo`.

* `hansolo`: runs `rsync` to copy cookbooks and data bags to the target nodes, generates a manifest and executes `chef-solo` against the generated manifest.
* `hansolo-databag`: Manages data bags.
* `hansolo-ssh`: SSHs into one of the target nodes.

To see what options can be supplied, run the command with `-h` or `--help`.


## `Hanfile` options

```ruby
Hansolo.configure do |config|
  # Path to SSH keys
  config.keydir = '~/.ssh/chef'

  # Gateway server if nodes are in a private network. Must be a valid ssh URI
  # or URI instance.
  config.gateway = 'ssh://user@gateway.example.com:20202'

  # Name of the application
  config.app = 'blog'

  # Nodes to run `chef-solo` on. Can be a single or array of ssh URIs or URI
  # instance.
  config.target = 'ssh://user@blog.example.com'

  # List of recipes to run.
  config.runlist = ['recipe']

  # Local path where cookbooks should be installed to using
  # `Hansolo.librarian`. Defaults to `./tmp/data_bags`
  config.cookbooks_path = '/tmp/chef/cookbooks'

  # Local path where data bags will be written when using `hansolo-databag`.
  # Defaults to `./tmp/cookbooks`
  config.data_bags_path = '/tmp/chef/cookbooks'

  # Command to run on the node after SSHing.
  config.post_ssh_command = 'export RAILS_ENV=production; cd /srv/blog/current'

  # Which chef cookbook manager to use. Currently, only `#berkshelf` is
  # supported.
  config.librarian = :berkshelf

  # SSH options to use when running `rsync` or `hansolo-ssh`.
  # Defaults to `-q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no`.
  config.ssh_options = '-vvv'
end
```

## Providers

`hansolo`'s behavior can be augmented by different providers by requiring them
in a `Hanfile`. Currently, AWS is the only provider provided.

```ruby
# Add AWS functionality to the toolset
require 'hansolo/providers/aws'

Hansolo.configure do |config|
  # ...
end
```

### AWS Provider

The AWS provider augments `hansolo` to store data\_bags in S3 and adds the
ability to query EC2 for the IP address of the gateway and/or target nodes.

Data bags are stored in a bucket with the name `data_bags-:app`. The bucket is
created if it does not exist.

To have the IP address of the gateway queried, use the following URI scheme:
`<tag_name>://user@<value>:port`. The `<tag_name>` is the name of any tag on
the instance (e.g. `Name://user@bastion`).

To query instances, set `Hansolo.target` to a hash with the keys `:user`,
`:host`, and optionally `:port` (if not `22`). The `:host` key should be set to
the tag to query and the value should be the name of the application (e.g.
`role://user@api`).

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
