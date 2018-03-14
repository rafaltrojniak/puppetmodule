# == Class: puppet::mcollective
#
# This class manages MCollective - supports puppet_agent packaging and puppet >= 5
#
# Shared paramaters are set here, and can be overridden in the puppet::mcollective::client and puppet::mcollective::server classes
#
#
# === Parameters:
#
# [*package*]
#   The name of the package to install or remove.
#
# [*service*]
#   The name of the service to manage.
#
# [*etcdir*]
#   Location of mcollective configuration files.
#
# [*libdir*]
#   Location of mcollective ruby lib directory.
#
# [*logfile*]
#   If logger_type is file, this is used.
#
# [*hosts*]
#   An array of middleware brokers to connect.
#
# [*collectives*]
#   An array of collectives to support.
#
# [*server_user*]
#   The username servers will use to authenticate.
#
# [*server_password*]
#   The password servers will use to authenticate.
#
# [*client_user*]
#   The username clients will use to authenticate.
#
# [*client_password*]
#   The password clients will use to authenticate.
#
# [*broker_user*]
#   The username brokers will use to authenticate.
#
# [*broker_password*]
#   The password brokers will use to authenticate to each other.
#   Required if hosts > 1
#
# [*security_provider*]
#   Values: psk (default), sshkey, ssl, aes_security
#
# [*psk_key*]
#   Pre-shared key if provider is psk.
#
# [*psk_callertype*]
#   Valid to put in the 'caller' field of each request.
#   Values: uid (default), gid, user, group, identity
#
# [*connector*]
#   Which middleware connector to use. Values: 'activemq' (default) or 'rabbitmq'
#
# [*connector_ssl*]
#   Use SSL for connection? Values: false (default), true
#   Should change port to 61614 if this is enabled
#
# [*connector_ssl_type*]
#   Which type of SSL encryption should be used? Values: anonymous (default), trusted
#
# [*port*]
#   Which port to connect to.
#
# [*registerinterval*]
#   How often to resend registration information in seconds.
#
#
class puppet::mcollective (

  # Package and Service defaults that are OS-specific, can override in Hiera
  String                                            $package                        = 'puppet-agent',
  String                                            $service                        = $::puppet::params::mcollective_service_name,
  String                                            $etcdir                         = $::puppet::params::mcollective_etcdir,
  String                                            $libdir                         = $::puppet::params::mcollective_libdir,
  String                                            $logfile                        = $::puppet::params::mcollective_logfile,
  String                                            $classesfile                    = $::puppet::params::mcollective_classesfile,
  String                                            $ssldir                         = $::puppet::params::puppet_ssldir,

  # Hosts and collectives
  Array $hosts,
  Array                                             $collectives                    = ['mcollective'],


  # Authorization
  String                                            $server_user                    = 'server',
  Optional[String]                                  $server_password                = undef,
  String                                            $client_user                    = 'client',
  Optional[String]                                  $client_password                = undef,
  String                                            $broker_user                    = 'admin',
  Optional[String]                                  $broker_password                = undef,

  Enum['psk', 'sshkey', 'ssl', 'aes_security']      $security_provider              = 'psk',
  Optional[String]                                  $psk_key                        = undef,
  String                                            $psk_callertype                 = 'uid',

  # Connector settings
  Enum['activemq', 'rabbitmq']                      $connector                      = 'activemq',
  Boolean                                           $connector_ssl                  = false,
  String                                            $connector_ssl_type             = 'anonymous',
  Optional[Integer]                                 $port                           = undef,
  Boolean                                           $activemq_base64                = false,

  Integer                                           $registerinterval               = 600,

  # Optional files distribution
  Optional[String]                                  $site_module                    = undef,

)
  inherits puppet::params {


  # Make sure puppet_agent >= 5 is instaleed #
  if ( versioncmp("${::puppet_agent_major_version}", '5') < 0 ) {
    fail('These classes for mcollective are only supported with puppet_agent >= 5')
  }


  # Set the appropriate default port based on whether SSL is enabled
  if( $port != undef ) {
    $_port = $port
  }
  else {
    $_port = $connector_ssl ? { true => 61614, default => 61613 }
  }

  # ensure the ssl directory exists for the lient and server modules
  if( ( $mcollective::security_provider == 'aes_security' ) or ( $mcollective::security_provider == 'ssl' ) ) {
    file { "${etcdir}/ssl":
      ensure => directory,
      owner  => 0,
      group  => 0,
      mode   => '0555',
    }
    if( $mcollective::security_provider == 'ssl' ) {
      file { "${etcdir}/ssl/server":
        ensure => directory,
        owner  => 0,
        group  => 0,
        mode   => '0555',
      }
      $_site_module = $site_module ? {
        undef   => '',
        default => "${site_module}/",
      }
      @file { "${etcdir}/ssl/server/public.pem":
        ensure  => file,
        owner   => 0,
        group   => 0,
        mode    => '0444',
        links   => follow,
        replace => true,
        source  => "puppet:///modules/${_site_module}mcollective/ssl/server/public.pem",
      }
    }
  }


}
