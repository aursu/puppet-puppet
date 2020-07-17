# puppet::params
#
# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include puppet::params
class puppet::params {
    $platform_name       = 'puppet5'
    $package_name        = "${platform_name}-release"
    $os_version          = $::operatingsystemmajrelease
    case $::osfamily {
        'Suse': {
            $repo_urlbase = "https://yum.puppet.com/${platform_name}"
            $os_abbreviation  = 'sles'
            $version_codename = "${os_abbreviation}-${os_version}"
            $package_provider = 'rpm'
            $package_filename = "${package_name}-${version_codename}.noarch.rpm"
        }
        'Debian': {
            $repo_urlbase = 'https://apt.puppetlabs.com'
            $version_codename = $::lsbdistcodename
            $package_provider = 'dpkg'
            $package_filename = "${package_name}-${version_codename}.deb"
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
            $repo_urlbase = "https://yum.puppet.com/${platform_name}"
            $version_codename = "${os_abbreviation}-${os_version}"
            $package_provider = 'rpm'
            $package_filename = "${package_name}-${version_codename}.noarch.rpm"
        }
    }
    $platform_repository = "${repo_urlbase}/${package_filename}"
    $agent_package_name  = 'puppet-agent'
    $server_package_name = 'puppetserver'
    $r10k_package_name   = 'r10k'
    $ruby_path           = '/opt/puppetlabs/puppet/bin/ruby'
    $gem_path            = '/opt/puppetlabs/puppet/bin/gem'
    $r10k_path           = '/opt/puppetlabs/puppet/bin/r10k'
    $puppet_path         = '/opt/puppetlabs/puppet/bin/puppet'
    $service_name        = 'puppetserver'
    $puppet_config       = '/etc/puppetlabs/puppet/puppet.conf'
    $r10k_config_file    = '/etc/puppetlabs/r10k/r10k.yaml'
    $eyaml_keys_path     = '/etc/puppetlabs/puppet/keys'
    $eyaml_public_key    = 'public_key.pkcs7.pem'
    $eyaml_private_key   = 'private_key.pkcs7.pem'

    # dont't change values below - never!
    $vardir              = '/opt/puppetlabs/server/data/puppetserver'
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

    # Client authentication
    if $::puppet_sslpaths {
        $certdir       = $::puppet_sslpaths['certdir']['path']
        $privatekeydir = $::puppet_sslpaths['privatekeydir']['path']
        $requestdir    = $::puppet_sslpaths['requestdir']['path']
        $publickeydir  = $::puppet_sslpaths['publickeydir']['path']
    }
    else {
        # fallback to predefined
        $certdir       = '/etc/puppetlabs/puppet/ssl/certs'
        $privatekeydir = '/etc/puppetlabs/puppet/ssl/private_keys'
        $requestdir    = '/etc/puppetlabs/puppet/ssl/certificate_requests'
        $publickeydir  = '/etc/puppetlabs/puppet/ssl/public_keys'
    }
    $localcacert   = "${certdir}/ca.pem"
    # https://puppet.com/docs/puppet/5.3/lang_facts_and_builtin_vars.html#puppet-agent-facts
    if $::clientcert {
        $hostcert      = "${certdir}/${::clientcert}.pem"
        $hostprivkey   = "${privatekeydir}/${::clientcert}.pem"
        $hostpubkey    = "${publickeydir}/${::clientcert}.pem"
    }
    else {
        # fallback to fqdn
        $hostcert      = "${certdir}/${::fqdn}.pem"
        $hostprivkey   = "${privatekeydir}/${::fqdn}.pem"
        $hostpubkey    = "${publickeydir}/${::fqdn}.pem"
    }
}
