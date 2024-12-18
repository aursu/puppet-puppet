# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include puppet::server::setup::filesystem
class puppet::server::setup::filesystem inherits puppet::globals {
  $codedir = $puppet::globals::codedir
  $environmentpath = $puppet::globals::environmentpath

  file {
    default:
      ensure => directory,
      owner  => 'puppet',
      group  => 'puppet',
      mode   => '0750';
    $codedir: ;
    $environmentpath: ;
  }

  file {
    ['/etc/puppetlabs',
    '/etc/puppetlabs/puppet']:
      ensure => directory,
  }
}
