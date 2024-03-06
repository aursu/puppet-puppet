# @summary Global bootstrap parameters
#
# Defines parameters used globally during the bootstrap process
#
# @param bootstrap_path
#   Specifies the path to the bootstrap files. This path is predefined as `/root/bootstrap`.
#   It serves as the default location for all necessary bootstrap files and scripts.
#
# @param cwd
#   Defines the working directory for executing the r10k command and other related
#   bootstrap commands. By default, this is set to the same path as `bootstrap_path`,
#   ensuring a centralized location for running bootstrap operations.
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
  Optional[Stdlib::Unixpath] $cwd = $bootstrap_path,
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
