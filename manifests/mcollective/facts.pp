# == Class: puppet::mcollective::facts
#
# This module installs a cron script that puts Puppet facts in a file for MCollective to use
#
# === Example
#
# Hiera: 
#   mcollective::facts::cronjob::run_every: 15   # every quarter hour 
#
class puppet::mcollective::facts (
  $run_every = 'unknown',
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

  cron { 'mcollective-facts':
    ensure      => $enable,
    command     => "facter --puppet --yaml 2>/dev/null > ${yamlfile}.new && ! diff -q ${yamlfile}.new ${yamlfile} >/dev/null 2>&1 && mv ${yamlfile}.new ${yamlfile} >/dev/null 2>&1",
    minute      => $minute,
    environment => 'PATH=/bin:/usr/bin:/usr/sbin:/opt/puppetlabs/bin',
  }
}
