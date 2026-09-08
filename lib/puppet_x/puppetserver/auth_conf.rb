require 'hocon/config_factory'
require 'hocon/parser/config_document_factory'
require 'hocon/config_value_factory'

module PuppetX
  module Puppetserver
    # Shared handling of Puppet Server's auth.conf.
    #
    # Both `puppet_auth_rule` and `puppet_auth_setting` edit this one file:
    # the first owns entries in the `authorization.rules` list, the second owns
    # scalar settings beside it such as `allow-header-cert-info`.
    #
    # The state lives here rather than in each provider because a provider that
    # parses its own copy of the document and renders it back over the whole file
    # discards anything another provider changed in the same run - last writer
    # wins, silently. Sharing one document and one writer removes that class of
    # bug rather than relying on the two types never appearing together.
    module AuthConf
      DEFAULT_PATHS = [
        '/etc/puppetlabs/puppetserver/conf.d/auth.conf',
        '/etc/puppet/puppetserver/conf.d/auth.conf',
      ].freeze

      class << self
        # Replacing the content invalidates the parsed document: holding a
        # document parsed from content that has since been replaced means editing
        # a file that no longer matches what was read.
        def content=(value)
          @content = value
          @document = nil
        end

        # Likewise for the path - a different file means different content and a
        # different document.
        def file_name=(value)
          return if @file_name == value

          @file_name = value
          @content = nil
          @document = nil
        end

        def file_name
          @file_name ||= DEFAULT_PATHS.find { |path| File.exist?(path) } || DEFAULT_PATHS.first
        end

        def content
          @content ||= File.read(file_name) if File.exist?(file_name)
        end

        # The document every provider mutates. Parsed once per run.
        def document
          @document ||= if content
                          Hocon::Parser::ConfigDocumentFactory.parse_string(content)
                        else
                          base_document
                        end
        end

        attr_writer :document

        def config
          Hocon::ConfigFactory.parse_string(content) if content
        end

        def save
          File.open(file_name, 'w') do |fh|
            fh.puts(document.render)
          end
        end

        def base_rule
          { 'deny' => '*',
            'match-request' => {
              'path' => '/',
              'type' => 'path',
            },
            'name' => 'puppetlabs deny all',
            'sort-order' => 999 }
        end

        # A minimally valid auth.conf, for a host where the file does not exist
        # yet. Deny-all rather than allow-all: an auth.conf we invent should fail
        # closed.
        def base_document
          empty = Hocon::Parser::ConfigDocumentFactory.parse_string('')
          base = empty.set_value('authorization.version', '1')
          rule_object = Hocon::ConfigValueFactory.from_map(base_rule)
          base.set_config_value('authorization.rules', Hocon::ConfigValueFactory.from_any_ref([rule_object]))
        end

        # Test hook: drops the parsed state so a subsequent call re-reads.
        def reset!
          @file_name = nil
          @content = nil
          @document = nil
        end
      end
    end
  end
end
