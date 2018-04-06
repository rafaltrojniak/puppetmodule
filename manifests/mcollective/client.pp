# == Class: puppet::mcollective::client
#
# This module manages the MCollective client application
#
# Shared paramaters are in the main class puppet::mcollective, and can be overridden here
# Only params not in the main class are documented here
#
#
# === Parameters
#
# [*unix_group*]
#   The unix group that will be allowed to read the client.cfg file.
#   This is security for the pre-shared-key when PSK is used.
#
# [*sshkey_known_hosts*]
#    Defines a known hosts file for use instead of ~/.ssh/known_hosts
#
# [*logger_type*]
#   Where to send log messages. You usually want the user to see them.
#   Values: console (default), syslog, file
#
# [*log_level*]
#   How verbose should logging be?
#   Values: fatal, error, warn (default), info, debug
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
# [*disc_method*]
#    Defines the default discovery method to use
#
# [*disc_options*]
#    Defines the default discovery options to use
#
# [*da_threshold*]
#    Defines the threshold used to determine when to use direct addressing
#
#
class puppet::mcollective::client (

  # Package and Service defaults that are OS-specific, can override in Hiera
  String                                            $package                        = $::puppet::mcollective::package,
  String                                            $service                        = $::puppet::mcollective::service,
  String                                            $libdir                         = $::puppet::mcollective::libdir,
  String                                            $etcdir                         = $::puppet::mcollective::etcdir,
  String                                            $ssldir                         = $::puppet::mcollective::ssldir,

  # This value can be overridden in Hiera or through class parameters
  String                                            $unix_group                     = 'root',

  # Hosts and collectives
  Array                                             $hosts                          = $::puppet::mcollective::hosts,
  Array                                             $collectives                    = $::puppet::mcollective::collectives,

  # Authorization
  String                                            $client_user                    = $::puppet::mcollective::client_user,
  String                                            $client_password                = $::puppet::mcollective::client_password,

  Enum['psk', 'sshkey', 'ssl', 'aes_security']      $security_provider              = $::puppet::mcollective::security_provider,
  String                                            $psk_key                        = $::puppet::mcollective::psk_key,
  String                                            $psk_callertype                 = $::puppet::mcollective::psk_callertype,

  # SSL Plugin Client Keys
  String                                            $ssl_public_key                 = "${::ssldir}/public_keys/${::clientcert}.pem",
  String                                            $ssl_private_key                = "${::ssldir}/private_keys/${::clientcert}.pem",

  # Connector settings
  Enum['activemq', 'rabbitmq']                      $connector                      = $::puppet::mcollective::connector,
  Boolean                                           $connector_ssl                  = $::puppet::mcollective::connector_ssl,
  String                                            $connector_ssl_type             = $::puppet::mcollective::connector_ssl_type,
  Integer                                           $port                           = $::puppet::mcollective::_port,
  Boolean                                           $activemq_base64                = $::puppet::mcollective::activemq_base64,

  # SSH know hosts #
  Optional[String]                                  $sshkey_known_hosts             = undef,

  # Logging
  String                                            $logfile                        = $::puppet::mcollective::logfile,
  Enum['syslog', 'file', 'console']                 $logger_type                    = 'console',
  Enum['fatal', 'error', 'warn', 'info', 'debug']   $log_level                      = 'warn',
  String                                            $logfacility                    = 'user',
  String                                            $keeplogs                       = '5',
  String                                            $max_log_size                   = '2097152',

  # MCO discovery
  String                                            $disc_method                    = 'mc',
  Optional[String]                                  $disc_options                   = undef,
  String                                            $da_threshold                   = '10',

) inherits puppet::mcollective {


  file { "${etcdir}/client.cfg":
    ensure  => file,
    owner   => root,
    group   => $unix_group,
    mode    => '0440',
    content => template( 'puppet/mcollective/client.cfg.erb' ),
    require => Package[ $package ],
  }

  # Management of SSL keys
  if( $security_provider == 'ssl' ) {
    # Ensure the package is installed before we create this directory
    Package[$package] -> File["${etcdir}/ssl"]

    # copy the server public keys to all servers
    realize File["${etcdir}/ssl/server/public.pem"]
  }

}
