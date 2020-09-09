require 'puppet'

Facter.add('puppet_sslcert') do
  setcode do
    result = {}
    clientcert = Facter.fact(:clientcert)
    name = if clientcert && clientcert.value
             clientcert.value
           else
             Facter.fact(:fqdn).value
           end

    puppet_sslpaths = Facter.fact(:puppet_sslpaths)
    paths = if puppet_sslpaths && puppet_sslpaths.value
              puppet_sslpaths.value
            else
              {
                'certdir' => { 'path' => '/etc/puppetlabs/puppet/ssl/certs' },
                'privatekeydir' => { 'path' => '/etc/puppetlabs/puppet/ssl/private_keys' }
              }
            end

    certdir = paths['certdir']['path']
    hostcert = "#{certdir}/#{name}.pem"
    if File.exist?(hostcert)
      result['hostcert'] = { 'path' => hostcert, 'data' => File.read(hostcert) }
    end

    localcacert = "#{certdir}/ca.pem"
    if File.exist?(localcacert)
      result['localcacert'] = { 'path' => localcacert, 'data' => File.read(localcacert) }
    end

    privatekeydir = paths['privatekeydir']['path']
    hostprivkey = "#{privatekeydir}/#{name}.pem"
    if File.exist?(hostprivkey)
      result['hostprivkey'] = { 'path' => hostprivkey, 'data' => File.read(hostprivkey) }
    end

    result
  end
end