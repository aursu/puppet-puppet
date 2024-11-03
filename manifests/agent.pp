# @summary Manages the installation, configuration, and scheduling of the Puppet agent.
#
# The `puppet::agent` class centralizes the setup of the Puppet agent by incorporating
# package installation, configuration, and scheduling. It organizes and coordinates the
# key components required for the agent to function, including repository management,
# configuration file setup, and scheduled execution.
#
# **Class Workflow:**
# - **Installation (`puppet::agent::install`):** Ensures the Puppet agent package is installed.
# - **Configuration (`puppet::agent::config`):** Configures agent-specific settings,
#   including the Puppet server to connect to, optional CA server, environment, and certname.
#   This step is controlled by the `manage_config` parameter.
# - **Setup (`puppet::setup`):** Optionally updates the hosts file for Puppet server resolution,
#   and creates any necessary directories or helper scripts.
# - **Scheduling (`puppet::agent::schedule`):** Configures periodic or on-boot scheduling
#   for the Puppet agent to enforce policies as required.
#
# **Dependencies and Optional Settings:**
# - Includes optional updates to the hosts file if `$hosts_update` is enabled.
# - Allows specifying a unique certname for agent identification (`$certname`).
# - The configuration step can be skipped by setting `manage_config` to `false`.
#
# **Execution Order:**
# - Ensures `puppet::agent::install` completes before running configuration (`puppet::agent::config`),
#   followed by scheduling (`puppet::agent::schedule`). If `manage_config` is `false`,
#   `puppet::agent::config` is skipped, and `puppet::agent::schedule` follows directly after installation.
#
# @param server [String] The hostname of the Puppet server the agent will connect to.
#   Defaults to 'puppet'.
# @param hosts_update [Boolean] Specifies if the hosts file should be updated to resolve
#   the Puppet server’s name. Defaults to `false`.
# @param ca_server [Optional[String]] The Certificate Authority (CA) server hostname if
#   different from the main Puppet server.
# @param certname [Optional[String]] A unique certificate name (certname) for the agent's
#   identification, if specified.
# @param manage_config [Boolean] Determines whether to apply agent configuration using
#   `puppet::agent::config`. When `false`, skips configuration and proceeds directly to scheduling.
#   Defaults to `true`.
#
# @example
#   include puppet::agent
#
# **Example Usage:**
# ```puppet
# class { 'puppet::agent':
#   server       => 'puppet.example.com',
#   hosts_update => true,
#   ca_server    => 'ca.example.com',
#   certname     => 'agent01.example.com',
#   manage_config => false,
# }
# ```
#
class puppet::agent (
  String $server = 'puppet',
  Boolean $hosts_update = false,
  Optional[String] $ca_server = undef,
  Optional[String] $certname = undef,
  Boolean $manage_config = true,
) {
  class { 'puppet::agent::install': }
  contain puppet::agent::install

  if $manage_config {
    class { 'puppet::agent::config':
      server           => $server,
      ca_server        => $ca_server,
      # lint:ignore:top_scope_facts
      node_environment => $::environment,
      # lint:endignore
      certname         => $certname,
    }

    Class['puppet::agent::install']
    -> Class['puppet::agent::config']
    -> Class['puppet::agent::schedule']
  }

  class { 'puppet::setup':
    hosts_update => $hosts_update,
  }

  include puppet::agent::schedule

  Class['puppet::agent::install']
  -> Class['puppet::agent::schedule']
}
