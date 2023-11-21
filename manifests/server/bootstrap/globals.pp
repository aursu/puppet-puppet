# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include puppet::server::bootstrap::globals
class puppet::server::bootstrap::globals (
  Array[
    Struct[{
        name                  => Stdlib::Fqdn,
        key_data              => String,
        key_prefix            => String,
        Optional[server]      => Stdlib::Fqdn,
        Optional[sshkey_type] => Openssh::KeyID,
        Optional[ssh_options] => Openssh::SshConfig,
    }]
  ] $access_data = [],
  Array[Openssh::SshConfig] $ssh_config = [],
) inherits puppet::globals {
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
}
