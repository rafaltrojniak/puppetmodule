Facter.add('puppet_user_uid') do
  confine :kernel => 'Linux'
  setcode do

    raw_uid = Facter::Util::Resolution.exec('/usr/bin/id -u puppet 2>/dev/null')

    if raw_uid != nil

      uid = raw_uid.
        lines.
        to_a.
        select { |line| line.match(/^[0-9]+$/) }.
        first.
        rstrip

    else

      uid = nil

    end

    uid

  end
end

Facter.add('puppet_user_gid') do
  confine :kernel => 'Linux'
  setcode do

    raw_gid = Facter::Util::Resolution.exec('/usr/bin/id -g puppet 2>/dev/null')

    if raw_gid != nil

      gid = raw_gid.
        lines.
        to_a.
        select { |line| line.match(/^[0-9]+$/) }.
        first.
        rstrip

    else

      gid = nil

    end

    gid

  end
end
