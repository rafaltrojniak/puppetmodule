# == Fact: local_cert_signatures
#
# A custom fact for local ca signatures
#
Facter.add("local_cert_signatures") do
  setcode do

    md_hash = {}

    Find.find('/usr/local/share/ca-certificates') do |file_path|
      if File.file?(file_path)
        if not file_path.end_with?('puppet-ca.crt')
          md_hash[Digest::MD5.hexdigest(File.read(file_path))] = file_path
        end
      end
    end

    if md_hash.length > 0
      md_hash
    end

  end
end
