# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include puppet::server::setup::filesystem
class puppet::server::setup::filesystem inherits puppet::params {
  $codedir = $puppet::params::codedir
  $environmentpath = $puppet::params::environmentpath

  file {
    default:
      ensure => directory,
      owner  => 'puppet',
      group  => 'puppet',
      mode   => '0750';
    $codedir: ;
    $environmentpath: ;
  }
}
