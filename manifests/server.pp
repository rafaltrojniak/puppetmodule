# Class: puppet::server
#
# This class installs and configures puppetserver
#
# Parameters:
#  ['user_id']                  - The userid of the puppet user
#  ['group_id']                 - The groupid of the puppet group
#  ['puppet_user']              - The user name of the puppet user
#  ['puppet_group']             - The group name of the puppet user
#  ['modulepath']               - Module path to be served by the puppet master
#  ['manifest']                 - Manifest path
#  ['external_nodes']           - ENC script path
#  ['node_terminus']            - Node terminus setting, is overridden to 'exec' if external_nodes is set
#  ['hiera_config']             - Hiera config file path
#  ['reports']                  - Turn on puppet reports
#  ['certname']                 - The certname the puppet master should use
#  ['autosign']                 - Auto sign agent certificates default false
#  ['ca']                       - This master is a CA
#  ['ca_ttl']                   - Cert expirery ttl - defaulting to 10 years [ 315360000 secs ]
#  ['reporturl']                - Url to send reports to, if reporting enabled
#  ['puppet_ssldir']            - Puppet sll directory
#  ['puppet_vardir']            - Vardir used by puppet
#  ['puppet_server_package']    - Puppet server package
#  ['puppet_server_service']    - Puppet server service
#  ['puppet_server_service_requires'] - List of extra services that the puppet_server_service requeres - defaults to an empty list
#  ['puppet_server_defaults']   - Puppet server service defaults
#  ['version']                  - Version of the puppet master package to install
#  ['dns_alt_names']            - Comma separated list of alternative DNS names
#  ['digest_algorithm']         - The algorithm to use for file digests.
#  ['strict_variables']         - Makes the parser raise errors when referencing unknown variables
#  ['serialization_format']     - defaults to undef [ which means JSON/PSON ], otherwise it sets the preferred_serialization_format param (currently only msgpack is supported)
#  ['file_server_mounts']       - An array of hashes describing puppet file server mounts, hashes must include keys, 'name', 'path, and optionally 'desc'. Defaults to undef, which removes the config.
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
  String                                                $user_id                       = $::puppet_user_uid,
  String                                                $group_id                      = $::puppet_user_gid,
  String                                                $puppet_user                   = $::puppet::params::puppet_user,
  String                                                $puppet_group                  = $::puppet::params::puppet_group,
  String                                                $confdir                       = $::puppet::params::confdir,
  String                                                $puppet_conf                   = $::puppet::params::puppet_conf,
  String                                                $modulepath                    = $::puppet::params::modulepath,
  String                                                $manifest                      = $::puppet::params::manifest,
  Optional[String]                                      $external_nodes                = undef,
  Optional[Enum['plain', 'exec', 'classifier']]         $node_terminus                 = undef,
  String                                                $hiera_config                  = $::puppet::params::hiera_config,
  String                                                $environmentpath               = $::puppet::params::environmentpath,
  String                                                $reports                       = 'store',
  String                                                $certname                      = $::fqdn,
  Boolean                                               $autosign                      = false,
  Boolean                                               $ca                            = false,
  String                                                $ca_ttl                        = '315360000',
  Optional[String]                                      $reporturl                     = undef,
  String                                                $puppet_ssldir                 = $::puppet::params::puppet_ssldir,
  String                                                $puppet_vardir                 = $::puppet::params::puppet_vardir,
  String                                                $puppet_server_package         = $::puppet::params::puppet_server_package,
  String                                                $puppet_server_service         = $::puppet::params::puppet_server_service,
  Boolean                                               $puppet_server_service_enable  = $::puppet::params::puppet_server_service_enable,
  Array[String]                                         $puppet_server_service_requires = [],
  String                                                $puppet_server_defaults        = $::puppet::params::puppet_server_defaults,
  String                                                $puppet_server_confdir         = $::puppet::params::puppet_server_confdir,
  String                                                $puppet_server_conf_d          = $::puppet::params::puppet_server_conf_d,
  String                                                $puppet_server_services_d      = $::puppet::params::puppet_server_services_d,
  String                                                $java_heap                     = '-Xms1g -Xmx1g',
  String                                                $version                       = 'present',
  Array[String]                                         $dns_alt_names                 = ['puppet'],
  Enum['md5', 'sha256', 'sha384', 'sha512', 'sha224']   $digest_algorithm              = $::puppet::params::digest_algorithm,
  Optional[Boolean]                                     $strict_variables              = undef,
  Optional[Enum['msgpack']]                             $serialization_format          = undef,

  Optional[ Array[ Struct[ { name => String , path => String , Optional[desc] => String } ]]]   $file_server_mounts = undef,

) inherits puppet::params {

  anchor { 'puppet::server::begin': }

  if ! defined(User[$puppet_user]) {
    user { $puppet_user:
      ensure => present,
      uid    => $user_id,
      gid    => $puppet_group,
    }
  }

  if ! defined(Group[$puppet_group]) {
    group { $puppet_group:
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

  $_puppet_server_service_requires = unique(flatten(
    [
      Package[$puppet_server_package],
      File[$puppet_conf],
      Service[unique($puppet_server_service_requires)],
    ]
  ))

  if $puppet_server_service_enable {

    service { $puppet_server_service:
      ensure  => running,
      enable  => true,
      require => $_puppet_server_service_requires,
    }

  } else {

    service { $puppet_server_service:
      ensure  => stopped,
      enable  => false,
      require => $_puppet_server_service_requires,
    }

  }

  # Service params #
  if $::osfamily == 'Debian' {
    file { $puppet_server_defaults:
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
      require => Package[$puppet_server_package],
      notify  => Service[$puppet_server_service],
      content => template("puppet/${puppet_server_defaults}.erb"),
    }
  }

  if ! defined(File[$puppet_conf]){
    file { $puppet_conf:
      ensure  => 'file',
      mode    => '0644',
      require => File[$confdir],
      owner   => $puppet_user,
      group   => $puppet_group,
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
      owner   => $puppet_user,
      group   => $puppet_group,
      notify  => Service[$puppet_server_service],
    }
  }
  else {
    File<| title == $confdir |> {
      notify  +> Service[$puppet_server_service],
      require +> Package[$puppet_server_package],
    }
  }

  # This is no longer used - it's a legacy config file and is ignored #
  # Puppet auth settings #
  file { "${confdir}/auth.conf":
    ensure  => present,
    owner   => $puppet_user,
    group   => $puppet_group,
    content => template("puppet/server/auth.conf.erb"),
    require => File[$confdir],
  }


  # Puppetserver config dirs #
  file { $puppet_server_confdir:
    ensure  => directory,
    mode    => '0755',
    owner   => $puppet_user,
    group   => $puppet_group,
    require => Package[$puppet_server_package],
  }
  file { $puppet_server_conf_d:
    ensure  => directory,
    mode    => '0755',
    owner   => $puppet_user,
    group   => $puppet_group,
    require => File[$puppet_server_confdir],
  }
  file { $puppet_server_services_d:
    ensure  => directory,
    mode    => '0755',
    owner   => $puppet_user,
    group   => $puppet_group,
    require => File[$puppet_server_confdir],
    notify  => Service[$puppet_server_service],
  }

  # CA settings are here #
  file { "${puppet_server_services_d}/ca.cfg":
    ensure  => present,
    owner   => $puppet_user,
    group   => $puppet_group,
    content => template("puppet/server/ca.cfg.erb"),
    require => File[$puppet_server_services_d],
  }

  # File server mounts #
  if $file_server_mounts {

    file {"${confdir}/fileserver.conf":
      ensure  => present,
      mode    => '0640',
      owner   => $puppet_user,
      group   => $puppet_group,
      content => template("puppet/server/fileserver.conf.erb"),
      notify  => Service[$puppet_server_service],
    }

  } else {

    file {"${confdir}/fileserver.conf":
      ensure  => absent,
      notify  => Service[$puppet_server_service],
    }

  }

  file { $puppet_vardir:
    ensure  => directory,
    owner   => $puppet_user,
    group   => $puppet_group,
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

  ini_setting {'puppetmastercattl':
    ensure  => present,
    setting => 'ca_ttl',
    value   => $ca_ttl,
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
