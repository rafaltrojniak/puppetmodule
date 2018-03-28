# == Class: puppet::mcollective::facts
#
# This module installs a cron script that puts Puppet facts in a file for MCollective to use
#
#
class puppet::mcollective::facts (
  $run_every = 'unknown',
  $legacy    = true,
)
inherits puppet::mcollective {

  # if they passed in Hiera value use that.
  $enable = $run_every ? {
    'unknown' => 'absent',
    undef     => 'absent',
    ''        => 'absent',
    default   => 'present',
  }

  # Define the minute to be all if runevery wasn't defined
  $minute = $enable ? {
    'absent'  => '*',
    'present' => "*/${run_every}",
  }

  # shorten for ease of use
  $yamlfile = "${::puppet::mcollective::etcdir}/facts.yaml"


  if $legacy {
    $_legacy = '--show-legacy'
  } else {
    $_legacy = ''
  }

  if $::puppet_agent_installed {
    $facter_cmd = "/opt/puppetlabs/bin/facter --puppet ${_legacy} --yaml"
  } else {
    $facter_cmd = '/usr/bin/facter --puppet --yaml'
  }

  cron { 'mcollective-facts':
    ensure      => $enable,
    command     => "${facter_cmd} 2>/dev/null > ${yamlfile}.new && ! diff -q ${yamlfile}.new ${yamlfile} >/dev/null 2>&1 && mv ${yamlfile}.new ${yamlfile} >/dev/null 2>&1",
    minute      => $minute,
  }

}
