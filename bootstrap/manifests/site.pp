# ENC script for unknown hosts returns "production" environment, therefore
# puppet agent will install Puppet server on unknown host. To prevent this, add
# condition
if $::serverip == $::networking['ip'] {
  include role::puppet::master
}
