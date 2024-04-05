# frozen_string_literal: true
# https://www.puppet.com/docs/bolt/latest/testing_plans.html

# Load the spec_helper and BoltSpec library
require 'spec_helper'
require 'bolt_spec/plans'

describe 'puppet::server::bootstrap' do
  # Include the BoltSpec library functions
  include BoltSpec::Plans

  # Configure Puppet and Bolt before running any tests
  before(:all) do
    BoltSpec::Plans.init
  end
end
