# Class: puppet::params
#
# This class installs and configures parameters for Puppet
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class puppet::params {

  $puppet_server                    = 'puppet'
  $puppet_user                      = 'puppet'
  $puppet_group                     = 'puppet'
  $storeconfigs_dbserver            = $::fqdn
  $storeconfigs_dbport              = '8081'
  $certname                         = $::fqdn
  $puppet_docroot                   = '/etc/puppet/rack/public/'
  $puppet_passenger_port            = '8140'
  $puppet_server_port               = '8140'
  $puppet_agent_enabled             = true
  $apache_serveradmin               = 'root'
  $parser                           = 'current'
  $puppetdb_strict_validation       = true
  $digest_algorithm                 = 'md5'
  $puppet_run_interval              = 30
  $classfile                        = '$statedir/classes.txt'
  $package_provider                 = undef # falls back to system default

  $puppet_passenger_ssl_protocol    = 'TLSv1.2'
  $puppet_passenger_ssl_cipher      = 'AES256+EECDH:AES256+EDH'


  # Puppet 5 #

  $puppet_five_upgrade = hiera(warehouse_common::pup::agent_upgrade, false)

  if ( versioncmp("${::puppet_agent_major_version}", '5') < 0 ) {

    if $puppet_five_upgrade {
      $puppet_five_support = true
    } else {
      $puppet_five_support = false
    }

  } else {

    $puppet_five_support = true

  }

  # Hmmmmmm, pointless ??
  if $::puppet_server_major_version {

    $puppet_server_service_enable = true

  } else {

    $puppet_server_service_enable = false

  }

  if $puppet_five_support {
    $confdir                        = '/etc/puppetlabs/puppet'
    $hiera_config                   = "${confdir}/hiera.yaml"
    $codedir                        = '/etc/puppetlabs/code'
    $modulepath                     = "${codedir}/modules"
    $manifest                       = "${codedir}/manifests"
    $environmentpath                = "${codedir}/environments"
  } else {
    $confdir                        = '/etc/puppet'
    $hiera_config                   = '/etc/puppet/hiera.yaml'
    $modulepath                     = '/etc/puppet/modules'
    $manifest                       = '/etc/puppet/manifests/site.pp'
    $environments                   = 'config'
    # Only used when environments == directory
    $environmentpath                = "${confdir}/environments"
  }

  case $::osfamily {
    'RedHat': {
      $puppet_master_package        = 'puppet-server'
      $puppet_master_service        = 'puppetmaster'
      $puppet_agent_service         = 'puppet'
      $puppet_agent_package         = 'puppet'
      $puppet_defaults              = '/etc/sysconfig/puppet'
      $puppet_conf                  = '/etc/puppet/puppet.conf'
      $puppet_vardir                = '/var/lib/puppet'
      $puppet_ssldir                = '/var/lib/puppet/ssl'
      $passenger_package            = 'mod_passenger'
      $rack_package                 = 'rubygem-rack'
      $ruby_dev                     = 'ruby-devel'
    }
    'Suse': {
      $puppet_master_package        = 'puppet-server'
      $puppet_master_service        = 'puppetmasterd'
      $puppet_agent_service         = 'puppet'
      $puppet_agent_package         = 'puppet'
      $puppet_conf                  = '/etc/puppet/puppet.conf'
      $puppet_vardir                = '/var/lib/puppet'
      $puppet_ssldir                = '/var/lib/puppet/ssl'
      $passenger_package            = 'rubygem-passenger-apache2'
      $rack_package                 = 'rubygem-rack'
    }
    'Debian': {
      $puppet_master_package        = 'puppetmaster'
      $puppet_master_service        = 'puppetmaster'
      $puppet_server_package        = 'puppetserver'
      $puppet_server_service        = 'puppetserver'
      $puppet_agent_service         = 'puppet'
      $puppet_agent_package         = 'puppet'
      $puppet_defaults              = '/etc/default/puppet'
      $passenger_package            = 'libapache2-mod-passenger'
      $rack_package                 = 'librack-ruby'
      $ruby_dev                     = 'ruby-dev'
      $puppet_conf                  = "${confdir}/puppet.conf"
      $puppet_server_confdir        =  '/etc/puppetlabs/puppetserver'
      $puppet_server_conf_d         =  "${puppet_server_confdir}/conf.d"
      $puppet_server_services_d     =  "${puppet_server_confdir}/services.d"

      if $puppet_five_support {
        $puppet_vardir              = '/opt/puppetlabs/puppet/cache'
        $puppet_ssldir              = '/etc/puppetlabs/puppet/ssl'
      } else {
        $puppet_vardir              = '/var/lib/puppet'
        $puppet_ssldir              = '/var/lib/puppet/ssl'
      }

    }
    'FreeBSD': {
      $puppet_agent_service         = 'puppet'
      $puppet_agent_package         = 'sysutils/puppet'
      $puppet_conf                  = '/usr/local/etc/puppet/puppet.conf'
      $puppet_vardir                = '/var/puppet'
      $puppet_ssldir                = '/var/puppet/ssl'
    }
    'Darwin': {
      $puppet_agent_service         = 'com.puppetlabs.puppet'
      $puppet_agent_package         = 'puppet'
      $puppet_conf                  = '/etc/puppet/puppet.conf'
      $puppet_vardir                = '/var/lib/puppet'
      $puppet_ssldir                = '/etc/puppet/ssl'
    }
    default: {
      err('The Puppet module does not support your os')
    }
  }
}
