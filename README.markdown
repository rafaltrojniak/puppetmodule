# Puppet module #

This module provides classes for managing the puppet agent and puppet server. 
Please note this will not setup puppetdb.
will only work on puppet versions newer than 5.5.0

## Prerequisites ##
If you are using a RedHat based OS you also need to have the EPEL repo configured
as this module requires the passenger apache module.

Requires the following modules from puppetforge: [stdlib](https://forge.puppetlabs.com/puppetlabs/stdlib), [apache](https://forge.puppetlabs.com/puppetlabs/apache), [concat](https://forge.puppetlabs.com/puppetlabs/concat), [inifile](https://forge.puppetlabs.com/puppetlabs/inifile)


## Server ##

  class { 'puppet::server':
    autosign       => true,
    certname       => 'puppet.some.domain.name'
    external_nodes => '/etc/puppetlabs/puppet/enc.sh',
  }


## Puppet Environments ##

Puppet supports _Directory Environments_ only.


## Agent ##

  class { 'puppet::agent':
    puppet_server => master.puppetlabs.vm,
    environment   => production,
    splay         => true,
  }


## Testing ##

Testing is out of date, and hence will fail.
The below instructions worked as of when it was last updated.

Install gems:

    bundle install --path vendor/bundle

Lint and rspec-puppet:

    bundle exec rake lint
    bundle exec rake spec

If you have a working Vagrant setup you can run the rspec-system tests:

    bundle exec rake beaker

To use different base boxes than the default pass the name of the box to
the rake command with the ```BEAKER_set``` environment variable (check out
.nodelist.yml for box names):

    BEAKER_set=ubuntu-server-1404-x64 bundle exec rake beaker
