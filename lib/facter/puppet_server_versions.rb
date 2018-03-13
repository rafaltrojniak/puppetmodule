Facter.add('puppet_server_version') do
  confine :kernel => 'Linux'
  setcode do

    raw_version = Facter::Util::Resolution.exec('puppetserver --version 2>&1')

    if raw_version != nil
      version = Facter::Util::Resolution.exec('puppetserver --version 2>&1').
        lines.
        to_a.
        select { |line| line.match(/^puppetserver version:/) }.
        first.
        rstrip
    else
      version = nil
    end

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
