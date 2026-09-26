# frozen_string_literal: true

# Operating systems whose module-level default platform is OpenVox rather than
# puppet8, because Puppet Inc publishes no packages for them. Mirrors
# data/os/Rocky/10.yaml and data/os/Fedora/41.yaml.
def openvox_default?(os)
  os.match?(%r{^(rocky-10|fedora-41)-})
end
