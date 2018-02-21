# Class: puppet::server
#
# This class installs and configures puppetserver
#
# Parameters:
#  ['user_id']                  - The userid of the puppet user
#  ['group_id']                 - The groupid of the puppet group
#  ['modulepath']               - Module path to be served by the puppet master
#  ['manifest']                 - Manifest path
#  ['external_nodes']           - ENC script path
#  ['node_terminus']            - Node terminus setting, is overridden to 'exec' if external_nodes is set
#  ['hiera_config']             - Hiera config file path
#  ['reports']                  - Turn on puppet reports
#  ['certname']                 - The certname the puppet master should use
#  ['autosign']                 - Auto sign agent certificates default false
#  ['ca']                       - This master is a CA
#  ['reporturl']                - Url to send reports to, if reporting enabled
#  ['puppet_ssldir']            - Puppet sll directory
#  ['puppet_docroot']           - Doc root to be configured in apache vhost
#  ['puppet_vardir']            - Vardir used by puppet
#  ['puppet_server_package']    - Puppet master package
#  ['puppet_server_service']    - Puppet master service
#  ['version']                  - Version of the puppet master package to install
#  ['dns_alt_names']            - Comma separated list of alternative DNS names
#  ['digest_algorithm']         - The algorithm to use for file digests.
#  ['strict_variables']         - Makes the parser raise errors when referencing unknown variables
#  ['serialization_format']     - defaults to undef [ which means JSON/PSON ], otherwise it sets the preferred_serialization_format param (currently only msgpack is supported)
#
# Notes:
#
# This class only supports puppetserver, and hence does not impliment passenger support
#
# Requires:
#
#  - inifile
#  - Class['puppet::params']
#
#
class puppet::server (
  $user_id                       = undef,
  $group_id                      = undef,
  $confdir                       = $::puppet::params::confdir,
  $puppet_conf                   = $::puppet::params::puppet_conf,
  $modulepath                    = $::puppet::params::modulepath,
  $manifest                      = $::puppet::params::manifest,
  $external_nodes                = undef,
  $node_terminus                 = undef,
  $hiera_config                  = $::puppet::params::hiera_config,
  $environmentpath               = $::puppet::params::environmentpath,
  $reports                       = store,
  $certname                      = $::fqdn,
  $autosign                      = false,
  $ca                            = false,
  $reporturl                     = undef,
  $puppet_ssldir                 = $::puppet::params::puppet_ssldir,
  $puppet_docroot                = $::puppet::params::puppet_docroot,
  $puppet_vardir                 = $::puppet::params::puppet_vardir,
  $puppet_server_package         = $::puppet::params::puppet_server_package,
  $puppet_server_service         = $::puppet::params::puppet_server_service,
  $puppet_server_service_enable  = $::puppet::params::puppet_server_service_enable,
  $puppet_server_confdir         = $::puppet::params::puppet_server_confdir,
  $puppet_server_conf_d          = $::puppet::params::puppet_server_conf_d,
  $puppet_server_services_d      = $::puppet::params::puppet_server_services_d,
  $version                       = 'present',
  $dns_alt_names                 = ['puppet'],
  $digest_algorithm              = $::puppet::params::digest_algorithm,
  $strict_variables              = undef,
  $serialization_format          = undef,
) inherits puppet::params {

  anchor { 'puppet::server::begin': }

  if ! defined(User[$::puppet::params::puppet_user]) {
    user { $::puppet::params::puppet_user:
      ensure => present,
      uid    => $user_id,
      gid    => $::puppet::params::puppet_group,
    }
  }

  if ! defined(Group[$::puppet::params::puppet_group]) {
    group { $::puppet::params::puppet_group:
      ensure => present,
      gid    => $group_id,
    }
  }

  if $::osfamily == 'Debian' {

    Exec<| title == 'apt_update' |> -> Package <| tag == 'puppet::server' |>

  }

  package { $puppet_server_package:
    ensure  => $version,
  }

  if $puppet_server_service_enable {

    service { $puppet_server_service:
      ensure  => running,
      enable  => true,
      require => [Package[$puppet_server_package],File[$puppet_conf]],
    }

  } else {

    service { $puppet_server_service:
      ensure  => stopped,
      enable  => false,
      require => [Package[$puppet_server_package],File[$puppet_conf]],
    }

  }

  if ! defined(File[$puppet_conf]){
    file { $puppet_conf:
      ensure  => 'file',
      mode    => '0644',
      require => File[$confdir],
      owner   => $::puppet::params::puppet_user,
      group   => $::puppet::params::puppet_group,
      notify  => Service[$puppet_server_service],
    }
  }
  else {
    File<| title == $puppet_conf |> {
      notify  => Service[$puppet_server_service],
    }
  }

  if ! defined(File[$confdir]) {
    file { $confdir:
      ensure  => directory,
      mode    => '0755',
      require => Package[$puppet_server_package],
      owner   => $::puppet::params::puppet_user,
      group   => $::puppet::params::puppet_group,
      notify  => Service[$puppet_server_service],
    }
  }
  else {
    File<| title == $confdir |> {
      notify  +> Service[$puppet_server_service],
      require +> Package[$puppet_server_package],
    }
  }

  # Puppet auth settings #
  file { "${confdir}/auth.conf":
    ensure  => present,
    owner   => $::puppet::params::puppet_user,
    group   => $::puppet::params::puppet_group,
    content => template("puppet/server/auth.conf.erb"),
    require => File[$confdir],
  }


  # Puppetserver config dirs #
  file { $puppet_server_confdir:
    ensure  => directory,
    mode    => '0755',
    owner   => $::puppet::params::puppet_user,
    group   => $::puppet::params::puppet_group,
    require => Package[$puppet_server_package],
  }
  file { $puppet_server_conf_d:
    ensure  => directory,
    mode    => '0755',
    owner   => $::puppet::params::puppet_user,
    group   => $::puppet::params::puppet_group,
    require => File[$puppet_server_confdir],
  }
  file { $puppet_server_services_d:
    ensure  => directory,
    mode    => '0755',
    owner   => $::puppet::params::puppet_user,
    group   => $::puppet::params::puppet_group,
    require => File[$puppet_server_confdir],
    notify  => Service[$puppet_server_service],
  }

  # CA settings are here #
  file { "${puppet_server_services_d}/ca.cfg":
    ensure  => present,
    owner   => $::puppet::params::puppet_user,
    group   => $::puppet::params::puppet_group,
    content => template("puppet/server/ca.cfg.erb"),
    require => File[$puppet_server_services_d],
  }

  file { $puppet_vardir:
    ensure  => directory,
    owner   => $::puppet::params::puppet_user,
    group   => $::puppet::params::puppet_group,
    notify  => Service[$puppet_server_service],
    require => Package[$puppet_server_package]
  }

  # Ini defaults #
  Ini_setting {
      path    => $puppet_conf,
      require => File[$puppet_conf],
      notify  => Service[$puppet_server_service],
      section => 'master',
  }

  ini_setting {'puppetmasterenvironmentpath':
    ensure  => $present,
    setting => 'environmentpath',
    value   => $environmentpath,
    section => 'main',
  }

  if $external_nodes != undef {
    ini_setting {'puppetmasterencconfig':
      ensure  => present,
      setting => 'external_nodes',
      value   => $external_nodes,
    }

    ini_setting {'puppetmasternodeterminus':
      ensure  => present,
      setting => 'node_terminus',
      value   => 'exec'
    }
  }
  elsif $node_terminus != undef {
    ini_setting {'puppetmasternodeterminus':
      ensure  => present,
      setting => 'node_terminus',
      value   => $node_terminus
    }
  }

  ini_setting {'puppetmasterhieraconfig':
    ensure  => present,
    setting => 'hiera_config',
    value   => $hiera_config,
  }

  ini_setting {'puppetmasterautosign':
    ensure  => present,
    setting => 'autosign',
    value   => $autosign,
  }

  ini_setting {'puppetmastercertname':
    ensure  => present,
    setting => 'certname',
    value   => $certname,
  }

  # If not providing the CA - we need to change the CRL path #
  if ! $ca {
    # TODO: Add something here to get the CRL from the CA master
    # e.g. curl https://puppet:8140/puppet-ca/v1/certificate_revocation_list/ca
    ini_setting {'puppetmastercacrl':
      ensure  => present,
      setting => 'cacrl',
      value   => "${puppet_ssldir}/crl.pem",
    }
  }

  ini_setting {'puppetmasterreports':
    ensure  => present,
    setting => 'reports',
    value   => $reports,
  }

  if $reporturl != undef {
    ini_setting {'puppetmasterreport':
      ensure  => present,
      setting => 'reporturl',
      value   => $reporturl,
    }
  }

  ini_setting {'puppetmasterdnsaltnames':
    ensure  => present,
    setting => 'dns_alt_names',
    value   => join($dns_alt_names, ','),
  }

  ini_setting {'puppetmasterdigestalgorithm':
    ensure  => present,
    setting => 'digest_algorithm',
    value   => $digest_algorithm,
  }

  if $strict_variables != undef {
    validate_bool(str2bool($strict_variables))
    ini_setting {'puppetmasterstrictvariables':
      ensure  => present,
      setting => 'strict_variables',
      value   => $strict_variables,
    }
  }
  if $serialization_format != undef {
    ini_setting {'puppetagentserializationformatmaster':
      setting => 'preferred_serialization_format',
      value   => $serialization_format,
    }
  }

  anchor { 'puppet::server::end': }
}
