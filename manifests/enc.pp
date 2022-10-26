# puppet::enc
#
# Install ENC script
#
# @summary Install ENC script
#
# @example
#   include puppet::enc
#
# @param enc_template
# @param enc_data_source
# @param enc_envname
# @param ruby_path
# @param external_nodes
#
class puppet::enc (
  String $enc_template = $puppet::enc_template,
  Optional[Stdlib::Absolutepath] $enc_data_source = $puppet::enc_data_source,
  String  $enc_envname = $puppet::enc_envname,
  Stdlib::Absolutepath $ruby_path = $puppet::params::ruby_path,
  Stdlib::Absolutepath $external_nodes = $puppet::params::external_nodes,
) inherits puppet::params {
  file { 'enc-script':
    path    => $external_nodes,
    content => template($enc_template),
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
  }
}
