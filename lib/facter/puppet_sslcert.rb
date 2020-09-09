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
                'privatekeydir' => { 'path' => '/etc/puppetlabs/puppet/ssl/private_keys' },
                'requestdir' => { 'path' => '/etc/puppetlabs/puppet/ssl/certificate_requests' },
                'publickeydir' => { 'path' => '/etc/puppetlabs/puppet/ssl/public_keys' }
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
      result['hostprivkey'] = { 'path' => hostprivkey }
    end

    publickeydir = paths['publickeydir']['path']
    hostpubkey = "#{publickeydir}/#{name}.pem"
    if File.exist?(hostpubkey)
      result['hostpubkey'] = { 'path' => hostpubkey, 'data' => File.read(hostpubkey) }
    end

    requestdir = paths['requestdir']['path']
    hostreq = "#{requestdir}/#{name}.pem"
    if File.exist?(hostreq)
      result['hostreq'] = { 'path' => hostreq, 'data' => File.read(hostreq) }
    end

    result
  end
end