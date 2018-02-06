Facter.add('puppet_agent_installed') do
  confine :kernel => 'Linux'
  setcode do

    File.exists?('/opt/puppetlabs/puppet/bin/puppet')

  end
end
