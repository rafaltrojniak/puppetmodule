Facter.add('puppet_server_version') do
  confine :kernel => 'Linux'
  setcode do

    version = Facter::Util::Resolution.exec('puppetserver --version 2>&1').
      lines.
      to_a.
      select { |line| line.match(/^puppetserver version:/) }.
      first.
      rstrip

    if version != nil
      version.gsub(/^puppetserver version: ([^ ]+).*$/, '\1')
    else
      nil
    end

  end
end

Facter.add('puppet_server_major_version') do
  confine :kernel => 'Linux'
  setcode do

    version = Facter.value('puppet_server_version')

    if version != nil
      version.gsub(/^([0-9]+)\.[0-9]+\.[0-9]+$/, '\1')
    else
      nil
    end

  end
end
