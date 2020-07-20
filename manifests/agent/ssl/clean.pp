# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include puppet::agent::ssl::clean
class puppet::agent::ssl::clean (
  Stdlib::Unixpath
          $hostprivkey = $puppet::params::hostprivkey,
  Stdlib::Unixpath
          $hostpubkey  = $puppet::params::hostpubkey,
  Stdlib::Unixpath
          $hostcert    = $puppet::params::hostcert,
  Stdlib::Unixpath
          $hostreq     = $puppet::params::hostreq,
  Stdlib::Unixpath
          $localcacert = $puppet::params::localcacert,
) inherits puppet::params
{
  file {
    default:
      ensure => absent,
    ;
    $hostprivkey: ;
    $hostpubkey: ;
    $hostcert: ;
    $hostreq: ;
  }
}
