# == Class: puppet::mcollective::facts
#
# This module installs a cron script that puts Puppet facts in a file for MCollective to use
#
#
class puppet::mcollective::facts (
  Optional[Integer]   $run_every = undef,
  Boolean             $legacy    = true,
)
inherits puppet::mcollective {

  # if they passed in Hiera value use that.
  if $run_every {
    $enable = 'present'
  } else {
    $enable = 'absent'
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
    command     => "flock -n /tmp/facter.lock ${facter_cmd} 2>/dev/null > ${yamlfile}.new && ! diff -q ${yamlfile}.new ${yamlfile} >/dev/null 2>&1 && mv ${yamlfile}.new ${yamlfile} >/dev/null 2>&1",
    minute      => $minute,
  }

}
