class puppet::params {
  $platform_name       = 'puppet7'
  $os_version          = $facts['os']['release']['major']
  $os_family           = $facts['os']['family']
  case $os_family {
    'RedHat': {
      case $facts['os']['name'] {
        'Fedora': {
          $os_abbreviation = 'fedora'
        }
        default: {
          $os_abbreviation = 'el'
        }
      }
      $repo_urlbase = "https://yum.puppet.com/${platform_name}"
      $version_codename = "${os_abbreviation}-${os_version}"
      $package_provider = 'rpm'
      $ssh_keyscan_package = 'openssh-clients'
    }
    'Suse': {
      $repo_urlbase = "https://yum.puppet.com/${platform_name}"
      $os_abbreviation  = 'sles'
      $version_codename = "${os_abbreviation}-${os_version}"
      $package_provider = 'rpm'
      $ssh_keyscan_package = 'openssh-clients'
    }
    'Debian': {
      $repo_urlbase = 'https://apt.puppetlabs.com'
      $version_codename = $facts['os']['distro']['codename']
      $package_provider = 'dpkg'
      $ssh_keyscan_package = 'openssh-client'
    }
    default: {
      fail("Not known OS family ${os_family}")
    }
  }
  $package_name        = "${platform_name}-release"
  $package_filename    = "${package_name}-${version_codename}.noarch.rpm"
  $platform_repository = "${repo_urlbase}/${package_filename}"
  $agent_package_name  = 'puppet-agent'
  $server_package_name = 'puppetserver'
  $r10k_package_name   = 'r10k'
  $gem_path            = '/opt/puppetlabs/puppet/bin/gem'
  $r10k_path           = '/opt/puppetlabs/puppet/bin/r10k'
  $service_name        = 'puppetserver'
  $eyaml_keys_path     = '/etc/puppetlabs/puppet/keys'
  $eyaml_public_key    = 'public_key.pkcs7.pem'
  $eyaml_private_key   = 'private_key.pkcs7.pem'

  # https://www.puppet.com/docs/puppet/7/lang_facts_builtin_variables.html#lang_facts_builtin_variables-agent-facts
  if $facts['clientcert'] {
    $clientcert    = $facts['clientcert']
  }
  else {
    # fallback to fqdn
    $clientcert    = $facts['networking']['fqdn']
  }

  $confdir             = '/etc/puppetlabs/puppet'
  $server_confdir      = '/etc/puppetlabs/puppetserver'
  $cadir               = "${server_confdir}/ca"
  $signeddir           = "${cadir}/signed"

  $ssldir              = "${confdir}/ssl"
  $certdir             = "${ssldir}/certs"
  $publickeydir        = "${ssldir}/public_keys"
  $privatekeydir       = "${ssldir}/private_keys"

  $cacert              = "${cadir}/ca_crt.pem"
  $cacrl               = "${cadir}/ca_crl.pem"
  # https://www.puppet.com/docs/puppet/7/server/infrastructure_crl.html
  $infra_crl           = "${cadir}/infra_crl.pem"
  $localcacert         = "${certdir}/ca.pem"
  $hostcrl             = "${ssldir}/crl.pem"
  $hostpubkey          = "${publickeydir}/${clientcert}.pem"
  $hostcert            = "${certdir}/${clientcert}.pem"
  $cert_inventory      = "${cadir}/inventory.txt"
  $capub               = "${cadir}/ca_pub.pem"
  $infra_inventory     = "${cadir}/infra_inventory.txt"
  $infra_serial        = "${cadir}/infra_serials"
  $signed_cert         = "${signeddir}/${clientcert}.pem"
  $serial              = "${cadir}/serial"

  $hostprivkey         = "${privatekeydir}/${clientcert}.pem"
  $cakey               = "${cadir}/ca_key.pem"

  $ca_public_files = [
    $cacert,
    $cacrl,
    $infra_crl,
    $localcacert,
    $hostcrl,
    $hostpubkey,
    $hostcert,
    $cert_inventory,
    $capub,
    $infra_inventory,
    $infra_serial,
    $signed_cert,
    $serial,
  ]

  $ca_private_files = [
    $hostprivkey,
    $cakey,
  ]
}

class puppet::repo inherits puppet::params {
  $package_name        = $puppet::params::package_name
  $package_filename    = $puppet::params::package_filename
  $package_provider    = $puppet::params::package_provider
  $platform_repository = $puppet::params::platform_repository

  exec { "curl ${platform_repository} -s -o ${package_filename}":
    cwd     => '/tmp',
    path    => '/bin:/usr/bin',
    creates => "/tmp/${package_filename}",
    before  => Package['puppet-repository']
  }

  package { 'puppet-repository':
    name          => $package_name,
    provider      => $package_provider,
    source        => "/tmp/${package_filename}",
    allow_virtual => false,
  }
}

class puppet::agent::install inherits puppet::params {
  include puppet::repo

  $agent_package_name = $puppet::params::agent_package_name

  package { 'puppet-agent':
    ensure        => 'latest',
    name          => $agent_package_name,
    allow_virtual => false,
    require       => Package['puppet-repository'],
  }

  host { 'puppet':
    ensure => 'present',
    ip     => '127.0.0.1',
  }
}

class puppet::server::install inherits puppet::params {
  require puppet::agent::install

  $server_package_name = $puppet::params::server_package_name

  package { 'puppet-server':
    ensure        => 'latest',
    name          => $server_package_name,
    allow_virtual => false,
    require       => Package['puppet-agent'],
  }
}

class puppet::r10k::install inherits puppet::params {
  require puppet::agent::install

  $r10k_package_name = $puppet::params::r10k_package_name
  $gem_path          = $puppet::params::gem_path
  $r10k_path         = $puppet::params::r10k_path

  exec { "${gem_path} install ${r10k_package_name}":
    creates => $r10k_path,
    require => Package['puppet-agent'],
  }
}

class puppet::server::setup::keys inherits puppet::params {
  require puppet::server::install

  $eyaml_keys_path = $puppet::params::eyaml_keys_path
  $eyaml_public_key = $puppet::params::eyaml_public_key
  $eyaml_private_key = $puppet::params::eyaml_private_key

  file { $eyaml_keys_path:
    ensure  => 'directory',
    mode    => '0750',
    group   => 'puppet',
    require => Package['puppet-server'],
  }

  exec {
    default:
      path    => '/usr/bin:/bin',
      require => File[$eyaml_keys_path]
      ;
    "cp -a keys/public_key.pkcs7.pem ${eyaml_keys_path}/${eyaml_public_key}":
      onlyif  => 'test -f keys/public_key.pkcs7.pem',
      creates => "${eyaml_keys_path}/${eyaml_public_key}",
      before  => File["${eyaml_keys_path}/${eyaml_public_key}"],
      ;
    "cp -a keys/private_key.pkcs7.pem ${eyaml_keys_path}/${eyaml_private_key}":
      onlyif  => 'test -f keys/private_key.pkcs7.pem',
      creates => "${eyaml_keys_path}/${eyaml_private_key}",
      before  => File["${eyaml_keys_path}/${eyaml_private_key}"],
      ;
  }

  file {
    default:
      mode  => '0440',
      group => 'puppet',
      ;
    "${eyaml_keys_path}/${eyaml_public_key}": ;
    "${eyaml_keys_path}/${eyaml_private_key}": ;
  }
}

class puppet::server::setup::hiera {
  require puppet::server::install

  $environmentpath = '/etc/puppetlabs/code/environments'

  # default production ennvironment
  $env_path = "${environmentpath}/production"
  $data_path = "${env_path}/data"

  file { [$environmentpath, $env_path, $data_path]:
    ensure  => 'directory',
    require => Package['puppet-server'],
  }

  exec {
    default:
      path => '/usr/bin:/bin';
    "cp -a hiera.yaml ${env_path}/hiera.yaml":
      onlyif  => 'test -f hiera.yaml',
      unless  => "grep -q secrets.eyaml ${env_path}/hiera.yaml",
      require => File[$env_path],
      before  => File["${env_path}/hiera.yaml"],
      ;
    "cp -a data/secrets.eyaml ${data_path}/secrets.eyaml":
      onlyif  => 'test -f data/secrets.eyaml',
      creates => "${data_path}/secrets.eyaml",
      require => File[$data_path],
      before  => File["${data_path}/secrets.eyaml"],
      ;
  }

  file {
    default:
      mode  => '0440',
      group => 'puppet',
      ;
    "${env_path}/hiera.yaml": ;
    "${data_path}/secrets.eyaml": ;
  }
}

class puppet::global {
  $access_data = lookup({
      name          => 'profile::puppet::deploy::access',
      value_type    => Array[
        Struct[{
            name                  => Stdlib::Fqdn,
            key_data              => String,
            key_prefix            => String,
            Optional[server]      => Stdlib::Fqdn,
            Optional[sshkey_type] => Openssh::KeyID,
            Optional[ssh_options] => Openssh::SshConfig,
        }]
      ],
      default_value => [],
  })

  $ssh_access_config = $access_data.reduce([]) |$memo, $creds| {
    $key_name    = $creds['name']

    $server      = $creds['server'] ? {
      String  => $creds['server'],
      default => downcase($key_name)
    }

    $key_prefix  = $creds['key_prefix']

    $sshkey_type = $creds['sshkey_type'] ? {
      String  => $creds['sshkey_type'],
      default => 'ed25519'
    }

    $config      = {
      'Host'                  => $server,
      'StrictHostKeyChecking' => 'no',
      'IdentityFile'          => "~/.ssh/${key_prefix}.id_${sshkey_type}",
    } + $creds['ssh_options']

    $memo + [$config]
  }

  $ssh_config = lookup({
      name          => 'profile::puppet::deploy::ssh_config',
      value_type    => Array[Openssh::SshConfig],
      default_value => [],
  })
}

class puppet::server::setup::ssh inherits puppet::params {
  require puppet::server::setup::keys
  require puppet::server::setup::hiera
  include puppet::global

  $ssh_keyscan_package = $puppet::params::ssh_keyscan_package

  package { $ssh_keyscan_package:
    ensure => 'present',
  }

  file { '/root/.ssh':
    ensure => 'directory',
    mode   => '0700';
  }

  # Update ~/.ssh/known_hosts if gitservers.txt exists
  exec { 'ssh-keyscan -f gitservers.txt -t rsa >> /root/.ssh/known_hosts':
    path    => '/usr/bin:/bin',
    onlyif  => 'test -f gitservers.txt',
    unless  => 'grep -f gitservers.txt /root/.ssh/known_hosts',
    require => [
      Package[$ssh_keyscan_package],
      File['/root/.ssh'],
    ],
  }

  $access_data = $puppet::global::access_data
  $ssh_access_config = $puppet::global::ssh_access_config
  $ssh_config  = $puppet::global::ssh_config

  if $ssh_access_config[0] or $ssh_config[0] {
    openssh::ssh_config { 'root':
      ssh_config => $ssh_config + $ssh_access_config,
    }
  }

  if $access_data[0] {
    $access_data.each |$creds| {
      $key_name    = $creds['name']
      $sshkey_type = $creds['sshkey_type'] ? { String => $creds['sshkey_type'], default => 'ed25519' }

      openssh::priv_key { $key_name:
        user_name   => 'root',
        key_prefix  => $creds['key_prefix'],
        sshkey_type => $sshkey_type,
        key_data    => $creds['key_data'],
      }
    }
  }
}

class puppet::server::setup inherits puppet::params {
  require puppet::r10k::install
  require puppet::server::setup::ssh
  include puppet::global

  $access_data = $puppet::global::access_data

  if $access_data[0] {
    $r10k_path = $puppet::params::r10k_path

    exec { "${r10k_path} deploy environment -p":
      require => [
        Class['puppet::r10k::install'],
        Class['puppet::server::setup::ssh'],
      ],
    }
  }
}

class puppet::server::ca::import inherits puppet::params {
  require puppet::server::install

  # These PKI assets shold be cleaned up before CA import
  $timestamp     = Timestamp.new().strftime('%Y%m%dT%H%M%S')

  $import_path   = '/root/ca'

  $import_cakey  = "${import_path}/ca_key.pem"
  $import_cacert = "${import_path}/ca_crt.pem"
  $import_cacrl  = "${import_path}/ca_crl.pem"

  $import_condition = [
    "test -f ${import_cakey}",
    "test -f ${import_cacert}",
    "test -f ${import_cacrl}",
  ]

  $cacert           = $puppet::params::cacert

  $ca_public_files  = $puppet::params::ca_public_files
  $ca_private_files = $puppet::params::ca_private_files
  $ca_files         = $ca_public_files + $ca_private_files

  $ca_files.each |String $path| {
    exec { "backup ${path}":
      path    => '/bin:/usr/bin',
      command => "mv -n ${path} ${path}.${timestamp}",
      onlyif  => ["test -f ${path}"] + $import_condition,
      unless  => "diff -q ${import_cacert} ${cacert}",
      before  => Exec['puppetserver ca import'],
    }
  }

  $dns_alt_names = ['puppet', $facts['networking']['fqdn']]
  $subject_alt_names_param = join(['--subject-alt-names', join($dns_alt_names, ',')], ' ')
  $certname_param = "--certname ${facts['networking']['fqdn']}"

  exec { 'puppetserver ca import':
    path    => '/opt/puppetlabs/bin:/opt/puppetlabs/puppet/bin:/bin:/usr/bin',
    command => "puppetserver ca import ${subject_alt_names_param} ${certname_param} --private-key ${import_cakey} --cert-bundle ${import_cacert} --crl-chain ${import_cacrl}", # lint:ignore:140chars
    onlyif  => $import_condition,
    creates => $cacert,
    require => Class['puppet::server::install'],
  }
}

class puppet::service inherits puppet::params {
  require puppet::server::install
  require puppet::server::ca::import

  $service_name = $puppet::params::service_name

  service { 'puppet-server':
    ensure  => 'running',
    name    => $service_name,
    enable  => true,
    require => [
      Class['puppet::server::install'],
      Class['puppet::server::ca::import'],
    ],
  }
}

include puppet::server::setup
include puppet::service
