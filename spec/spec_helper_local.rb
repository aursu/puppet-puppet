# frozen_string_literal: true

# Operating systems whose module-level default platform is OpenVox rather than
# puppet8, because Puppet Inc publishes no packages for them. Mirrors
# data/os/Rocky/10.yaml and data/os/Fedora/41.yaml.
def openvox_default?(os)
  os.match?(%r{^(rocky-10|fedora-41)-})
end

# on_supported_os plus Amazon Linux 2023. facterdb carries amazon-2023 only for
# Facter 5, and on_supported_os picks factsets for the running Facter (4.x), so
# the release metadata.json declares is otherwise silently absent.
def on_supported_os_with_amazon
  amazon = [{ 'operatingsystem' => 'Amazon', 'operatingsystemrelease' => ['2023'] }]
  on_supported_os.merge(on_supported_os(supported_os: amazon, facterversion: '5.1'))
end
