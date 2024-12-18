# @summary Remove Puppet cerificate and keys on the host
#
# Remove Puppet cerificate and keys on the host
#
# @example
#   include puppet::agent::ssl::clean
#
# @param hostprivkey
# @param hostpubkey
# @param hostcert
# @param hostreq
# @param localcacert
#
class puppet::agent::ssl::clean (
  Stdlib::Unixpath $hostprivkey = $puppet::globals::hostprivkey,
  Stdlib::Unixpath $hostpubkey = $puppet::globals::hostpubkey,
  Stdlib::Unixpath $hostcert = $puppet::globals::hostcert,
  Stdlib::Unixpath $hostreq = $puppet::globals::hostreq,
  Stdlib::Unixpath $localcacert = $puppet::globals::localcacert,
) inherits puppet::globals {
  file {
    default:
      ensure => absent,
      ;
    $hostprivkey: ;
    $hostpubkey: ;
    $hostcert: ;
    $hostreq: ;
    $localcacert: ;
  }
}
