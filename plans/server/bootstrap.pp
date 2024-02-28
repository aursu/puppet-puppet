plan puppet::server::bootstrap (
  TargetSpec $targets,
  Puppet::Platform $collection = 'puppet8',
  Array[
    Struct[{
        name                  => String,
        key_data              => String,
        key_prefix            => String,
        Optional[server]      => String,
        Optional[sshkey_type] => String,
        Optional[ssh_options] => Hash[String, Variant[String, Integer, Array[String]]],
    }]
  ] $access_data = [],
  Array[
    Hash[String, Variant[String, Integer, Array[String]]]
  ] $ssh_config = [],
) {
  run_plan(facts, $targets)

  return apply($targets) {
    include puppet

    class { 'puppet::server::bootstrap::globals':
      access_data => $access_data,
      ssh_config  => $ssh_config,
    }

    class { 'puppet::server::bootstrap':
      platform_name => $collection,
    }
  }
}
