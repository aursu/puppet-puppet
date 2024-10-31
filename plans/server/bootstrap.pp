plan puppet::server::bootstrap (
  TargetSpec $targets,
  Puppet::Platform $collection = 'puppet8',
  String $access_data_lookup_key = 'puppet::server::bootstrap::access',
  String $ssh_config_lookup_key = 'puppet::server::bootstrap::ssh_config',
  Stdlib::Unixpath $bootstrap_path = '/root/bootstrap',
  Boolean $use_ssh = true,
  Optional[String] $certname = undef,
  Optional[String] $dns_alt_names = undef,
) {
  run_plan(facts, $targets)

  $apply_results =  apply($targets) {
    include puppet

    $access_data = lookup({
        name => $access_data_lookup_key,
        value_type => Array[
          Struct[{
              name                  => String,
              key_data              => String,
              key_prefix            => String,
              Optional[server]      => String,
              Optional[sshkey_type] => String,
              Optional[ssh_options] => Hash[String, Variant[String, Integer, Array[String]]],
          }]
        ],
        default_value => [],
    })

    $ssh_config = lookup({
        name => $ssh_config_lookup_key,
        value_type => Array[
          Hash[String, Variant[String, Integer, Array[String]]]
        ],
        default_value => [],
    })

    $dns_alt_names_list = lookup({
        name          => 'puppet::server::bootstrap::dns_alt_names',
        value_type    => Array[Stdlib::Host],
        default_value => $dns_alt_names ? {
          String  => split($dns_alt_names, /,/),
          default => [],
        },
    })

    class { 'puppet::globals':
      platform_name => $collection,
    }

    class { 'puppet::server::bootstrap::globals':
      access_data    => $access_data,
      ssh_config     => $ssh_config,
      bootstrap_path => $bootstrap_path,
    }

    class { 'puppet::server::bootstrap':
      # set it to 'production' because Bolt catalog's default is 'bolt_catalog'
      node_environment => 'production',
      use_ssh          => $use_ssh,
      certname         => $certname,
      dns_alt_names    => $dns_alt_names_list,
    }
  }

  # Print log messages from the report
  $apply_results.each |$result| {
    $result.report['logs'].each |$log| {
      out::message("${log['level'].upcase}: ${log['message']}")
    }
  }

  return $apply_results
}
