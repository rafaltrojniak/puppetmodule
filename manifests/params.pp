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
  $certname                         = $::fqdn
  $puppet_server_port               = '8140'
  $parser                           = 'current'
  $digest_algorithm                 = 'md5'
  $puppet_run_interval              = 30
  $classfile                        = '$statedir/classes.txt'
  $package_provider                 = undef # falls back to system default
  $puppet_server_service_enable     = true


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


  # Config locations #
  $confdir                          = '/etc/puppetlabs/puppet'
  $hiera_config                     = "${confdir}/hiera.yaml"
  $codedir                          = '/etc/puppetlabs/code'
  $modulepath                       = "${codedir}/modules"
  $manifest                         = "${codedir}/manifests"
  $environmentpath                  = "${codedir}/environments"


  # Mcollective #

  $mcollective_etcdir               = '/etc/puppetlabs/mcollective'
  $mcollective_libdir               = '/opt/puppetlabs/mcollective/plugins'
  $mcollective_logfile              = '/var/log/puppetlabs/mcollective/mcollective.log'
  $mcollective_classesfile          = '/opt/puppetlabs/puppet/cache/state/classes.txt'

  $mcollective_service_name         = 'mcollective'


  # Distro specific #

  case $::osfamily {
    'Debian': {
      $puppet_server_package        = 'puppetserver'
      $puppet_server_service        = 'puppetserver'
      $puppet_agent_service         = 'puppet'
      $puppet_agent_package         = 'puppet'
      $puppet_defaults              = '/etc/default/puppet'
      $ruby_dev                     = 'ruby-dev'
      $puppet_conf                  = "${confdir}/puppet.conf"
      $puppet_server_confdir        = '/etc/puppetlabs/puppetserver'
      $puppet_server_conf_d         = "${puppet_server_confdir}/conf.d"
      $puppet_server_services_d     = "${puppet_server_confdir}/services.d"
      $puppet_server_defaults       = "/etc/default/puppetserver"
      $puppet_vardir                = '/opt/puppetlabs/puppet/cache'
      $puppet_ssldir                = '/etc/puppetlabs/puppet/ssl'
    }
    default: {
      err('The Puppet module does not support your os')
    }
  }
}
