# puppet::params
#
# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include puppet::params
class puppet::params {
    $os_version          = $::operatingsystemmajrelease

    case $::osfamily {
        'Suse': {
            $os_abbreviation  = 'sles'
            $version_codename = "${os_abbreviation}-${os_version}"
            $package_provider = 'rpm'
        }
        'Debian': {
            $version_codename = $::lsbdistcodename
            $package_provider = 'dpkg'
        }
        # default is RedHat based systems
        default: {
            case $::operatingsystem {
                'Fedora': {
                    $os_abbreviation = 'fedora'
                }
                default: {
                    $os_abbreviation = 'el'
                }
            }
            $version_codename = "${os_abbreviation}-${os_version}"
            $package_provider = 'rpm'
        }
    }

    $agent_package_name  = 'puppet-agent'
    $server_package_name = 'puppetserver'
    $r10k_package_name   = 'r10k'
    $ruby_path           = '/opt/puppetlabs/puppet/bin/ruby'
    $gem_path            = '/opt/puppetlabs/puppet/bin/gem'
    $r10k_path           = '/opt/puppetlabs/puppet/bin/r10k'
    $r10k_cachedir       = '/var/cache/r10k'
    $puppet_path         = '/opt/puppetlabs/puppet/bin/puppet'
    $service_name        = 'puppetserver'
    $puppet_config       = '/etc/puppetlabs/puppet/puppet.conf'
    $r10k_config_file    = '/etc/puppetlabs/r10k/r10k.yaml'
    $eyaml_keys_path     = '/etc/puppetlabs/puppet/keys'
    $eyaml_public_key    = 'public_key.pkcs7.pem'
    $eyaml_private_key   = 'private_key.pkcs7.pem'

    if $facts['puppet_ssldir'] {
        $ssldir = $facts['puppet_ssldir']
    }
    else {
        $ssldir = '/etc/puppetlabs/puppet/ssl'
    }

    # Client authentication
    if $facts['puppet_sslpaths'] {
        $certdir       = $facts['puppet_sslpaths']['certdir']['path']
        $privatekeydir = $facts['puppet_sslpaths']['privatekeydir']['path']
        $requestdir    = $facts['puppet_sslpaths']['requestdir']['path']
        $publickeydir  = $facts['puppet_sslpaths']['publickeydir']['path']
    }
    else {
        # fallback to predefined
        $certdir       = "${ssldir}/certs"
        $privatekeydir = "${ssldir}/private_keys"
        $requestdir    = "${ssldir}/certificate_requests"
        $publickeydir  = "${ssldir}/public_keys"
    }

    # dont't change values below - never!
    $vardir              = '/opt/puppetlabs/server/data/puppetserver'
    $puppet_server       = '/opt/puppetlabs/bin/puppetserver'
    $logdir              = '/var/log/puppetlabs/puppetserver'
    $rundir              = '/var/run/puppetlabs/puppetserver'
    $pidfile             = '/var/run/puppetlabs/puppetserver/puppetserver.pid'
    $codedir             = '/etc/puppetlabs/code'

    # environmentpath
    # A search path for directory environments, as a list of directories
    # separated by the system path separator character. (The POSIX path
    # separator is ':', and the Windows path separator is ';'.)
    # This setting must have a value set to enable directory environments. The
    # recommended value is $codedir/environments. For more details,
    # see https://docs.puppet.com/puppet/latest/environments.html
    # Default: $codedir/environments

    $environmentpath     = "${codedir}/environments"

    # external_nodes
    # The external node classifier (ENC) script to use for node data. Puppet
    # combines this data with the main manifest to produce node catalogs.
    # To enable this setting, set the node_terminus setting to exec.
    # This setting’s value must be the path to an executable command that can
    # produce node information. The command must:
    #   * Take the name of a node as a command-line argument.
    #   * Return a YAML hash with up to three keys:
    #       - classes — A list of classes, as an array or hash.
    #       - environment — A string.
    #       - parameters — A list of top-scope variables to set, as a hash.
    #   * For unknown nodes, exit with a non-zero exit code.
    # Generally, an ENC script makes requests to an external data source.
    # For more info, see the ENC documentation.
    # Default: none

    $external_nodes      = '/usr/local/bin/puppet_node_classifier'

    $localcacert   = "${certdir}/ca.pem"
    # https://puppet.com/docs/puppet/5.3/lang_facts_and_builtin_vars.html#puppet-agent-facts
    if $facts['clientcert'] {
        $clientcert    = $facts['clientcert']
        $hostcert      = "${certdir}/${clientcert}.pem"
        $hostprivkey   = "${privatekeydir}/${clientcert}.pem"
        $hostpubkey    = "${publickeydir}/${clientcert}.pem"
        $hostreq       = "${requestdir}/${clientcert}.pem"
    }
    else {
        # fallback to fqdn
        $fqdn          = $facts['fqdn']
        $hostcert      = "${certdir}/${fqdn}.pem"
        $hostprivkey   = "${privatekeydir}/${fqdn}.pem"
        $hostpubkey    = "${publickeydir}/${fqdn}.pem"
        $hostreq       = "${requestdir}/${fqdn}.pem"
    }
}
