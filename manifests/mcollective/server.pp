# == Class: puppet::mcollective::server
#
# This module manages the MCollective server agent
#
# Shared paramaters are in the main class puppet::mcollective, and can be overridden here
# Only params not in the main class are documented here
#
#
# === Parameters
#
# [*ensure*]
#   Should the service be running?
#   Values: running (default), stopped
#
# [*enable*]
#   Should the service start at boot?
#   Values: true (default), false
#
# [*allow_managed_resources*]
#   Allow management of Puppet RAL-style resources?
#   Values: true (default), false
#
# [*resource_type_whitelist*]
#   Which resources are allowed to be managed?
#
# [*resource_type_blacklist*]
#   If whitelist is empty, which resources should be blocked?
#
# [*sshkey_authorized_keys*]
#    Defines a authorized keys file for use instead of ~/.ssh/authorized_keys
#
# [logrotate]
#    Rotate logs with logrotate module
#
# [*logger_type*]
#   Where to send log messages. You usually want the user to see them.
#   Values: syslog (default), file, console
#
# [*log_level*]
#   How verbose should logging be?
#   Values: fatal, error, warn, info (default), debug
#
# [*logfacility*]
#   If logger_type is syslog, which log facility to use?
#
# [*keeplogs*]
#   Any positive value will enable log rotation retaining that many files.
#   A blank or 0 value will disable log rotation.
#
# [*max_log_size*]
#    Max size in bytes for log files before rotation happens.
#
#
class puppet::mcollective::server (

  # Package and Service defaults that are OS-specific, can override in Hiera
  String                                            $package                        = $::puppet::mcollective::package,
  String                                            $service                        = $::puppet::mcollective::service,
  String                                            $libdir                         = $::puppet::mcollective::libdir,
  String                                            $etcdir                         = $::puppet::mcollective::etcdir,
  String                                            $classesfile                    = $::puppet::mcollective::classesfile,
  String                                            $ssldir                         = $::puppet::mcollective::ssldir,

  # These values can be overridden for a given server in Hiera
  Enum['stopped', 'running']                        $ensure                         = 'running',
  Boolean                                           $enable                         = true,

  # Hosts and collectives
  Array                                             $hosts                          = $::puppet::mcollective::hosts,
  Array                                             $collectives                    = $::puppet::mcollective::collectives,

  # Authorization
  String                                            $server_user                    = $::puppet::mcollective::server_user,
  String                                            $server_password                = $::puppet::mcollective::server_password,

  Enum['psk', 'sshkey', 'ssl', 'aes_security']      $security_provider              = $::puppet::mcollective::security_provider,
  String                                            $psk_key                        = $::puppet::mcollective::psk_key,

  # Connector settings
  Enum['activemq', 'rabbitmq']                      $connector                      = $::puppet::mcollective::connector,
  Boolean                                           $connector_ssl                  = $::puppet::mcollective::connector_ssl,
  String                                            $connector_ssl_type             = $::puppet::mcollective::connector_ssl_type,
  Integer                                           $port                           = $::puppet::mcollective::_port,
  Boolean                                           $activemq_base64                = $::puppet::mcollective::activemq_base64,

  Integer                                           $registerinterval               = $::puppet::mcollective::registerinterval,

  Boolean                                           $allow_managed_resources        = true,
  String                                            $resource_type_whitelist        = 'none',
  Optional[String]                                  $resource_type_blacklist        = undef,
  Optional[String]                                  $audit_logfile                  = undef,
  Optional[String]                                  $sshkey_authorized_keys         = undef,

  # Logging
  Boolean                                           $logrotate                      = true,
  String                                            $logfile                        = $::puppet::mcollective::logfile,
  Enum['syslog', 'file', 'console']                 $logger_type                    = 'syslog',
  Enum['fatal', 'error', 'warn', 'info', 'debug']   $log_level                      = 'info',
  String                                            $logfacility                    = 'user',
  String                                            $keeplogs                       = '5',
  String                                            $max_log_size                   = '2097152',

  Optional[String]                                  $site_module                    = $::puppet::mcollective::site_module,

)
  inherits puppet::mcollective {


  # Ensure the facts cronjob is set up or removed
  include puppet::mcollective::facts

  file { "${etcdir}/server.cfg":
    ensure  => file,
    owner   => 0,
    group   => 0,
    mode    => '0400',
    content => template( 'puppet/mcollective/server.cfg.erb' ),
    require => Package[ $package ],
    notify  => Service[ $service ],
  }

  $_site_module = $site_module ? {
    undef => '',
    default => "${site_module}/",
  }

  # Management of SSL keys
  if( ( $security_provider == 'aes_security' ) or ( $security_provider == 'ssl' ) ) {
    Package[$package] -> File["${etcdir}/ssl"]

    # copy client public keys to all servers
    file { "${etcdir}/ssl/clients":
      ensure  => directory,
      owner   => 0,
      group   => 0,
      mode    => '0755',
      links   => follow,
      purge   => true,
      force   => true,
      recurse => true,
      source  => "puppet:///modules/${_site_module}puppet/mcollective/ssl/clients",
      require => Package[ $package ],
      before  => Service[ $service ],
    }

    # For SSL module One keypair is shared across all servers
    if( $security_provider == 'ssl' ) {
      # Get the public key
      realize File["${etcdir}/ssl/server/public.pem"]

      # ...and the private key
      file { "${etcdir}/ssl/server/private.pem":
        ensure  => file,
        owner   => 0,
        group   => 0,
        mode    => '0400',
        links   => follow,
        replace => true,
        source  => "puppet:///modules/${_site_module}puppet/mcollective/ssl/server/private.pem",
        require => [ Package[ $package ], File["${etcdir}/ssl/server/public.pem"] ],
        before  => Service[ $service ],
      }
    }
  }

  #FIXME: got rid of this poliocy auth stuff - double check if needed.:# Policies used by the authorization plugins

  # Now start the daemon
  service { $service:
    ensure  => $ensure,
    enable  => $enable,
    require => Package[ $package ],
  }

  # logrotate config for the audit log
  if ( $logrotate and $audit_logfile ) {
    logrotate::rule { 'mcollective-auditlog':
      path          => $audit_logfile,
      create        => true,
      create_mode   => '0600',
      create_owner  => 'root',
      create_group  => 'root',
      rotate_every  => 'week',
      compress      => true,
      delaycompress => true,
      missingok     => true,
      mail          => false,
    }
  }
}
