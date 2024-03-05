# @summary Global bootstrap parameters
#
# Global bootstrap parameters
#
# @param bootstrap_path
#   Path to bootstrap files (defined by default as /root/bootstrap)
#
# @param cwd
#   Path where to run r10k command and look for resources with relative paths
#   (current path - if not provided, eg for puppet apply).
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
  Stdlib::Unixpath $bootstrap_path = '/root/bootstrap',
  Optional[Stdlib::Unixpath] $cwd = undef,
) {
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
