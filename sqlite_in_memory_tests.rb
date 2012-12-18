# a class to use when retrieving a connection pool and which stores the state of which pool to use
# class TestFast
#   class << self
#     def on?; !!@on; end
#     def off?; !@on; end
#     def initialize_special_connection_pool
#       unless ActiveRecord::Base.connection_handler.connection_pools[:test_fast]
#         # ActiveRecord::Base.configurations = YAML.load_file('config/database.yml').with_indifferent_access if ActiveRecord::Base.configurations.empty?
#         ActiveRecord::Base.connection_handler.connection_pools[:test_fast] = ActiveRecord::ConnectionAdapters::ConnectionPool.new(
#           ActiveRecord::Base::ConnectionSpecification.new(ActiveRecord::Base.configurations[:test_fast].extend(IKnowConfig), 'sqlite3_connection')
#         )
#       end
#     end
#     def turn_on
#       initialize_special_connection_pool
#       # swap in our custom connection handler
#       @old_conn_handler, ActiveRecord::Base.connection_handler = ActiveRecord::Base.connection_handler, FAST_TEST_CONN_HANDLER
#       @on=true
#     end
#     def turn_off
#       ActiveRecord::Base.connection_handler = @old_conn_handler
#       @on=false
#     end
#     def name
#       @name ||= self.to_s.underscore.to_sym
#     end
#   end
# end

# module IKnowConfig
#   def config
#     @config ||= YAML.load_file('config/database.yml').with_indifferent_access
#   end
# end

# custom connection handler that first looks at TestFast class attribute to determine behavior
# require 'active_record/connection_adapters/abstract/connection_pool'

# module ActiveRecord
#   module ConnectionAdapters
#     class CustomConnectionHandler < ConnectionHandler
#       def retrieve_connection_pool(klass)
#         if ::TestFast.on?
#           unless @connection_pools[TestFast.name]
#             @connection_pools[TestFast.name] = ActiveRecord::ConnectionAdapters::ConnectionPool.new(ActiveRecord::Base::ConnectionSpecification.new(ActiveRecord::Base.configurations[:test_fast].extend(IKnowConfig), 'sqlite3_connection'))
#           end
#           super(TestFast)
#         else
#           super
#         end
#       end
#       def retrieve_connection(klass)
#         if ::TestFast.on?
#           super(TestFast)
#         else
#           super
#         end
#       end
#       def connected?(klass)
#         if ::TestFast.on?
#           super(TestFast)
#         else
#           super
#         end
#       end
#       def remove_connection(klass)
#         if ::TestFast.on?
#           super(TestFast)
#         else
#           super
#         end
#       end
#     end
#     class ConnectionPool
#       # keep 2 connections per thread based on TestFast state
#       def current_connection_id
#         TestFast.on? ? -Thread.current.object_id : Thread.current.object_id
#       end
#     end
#   end
# end

# FAST_TEST_CONN_HANDLER = ActiveRecord::ConnectionAdapters::CustomConnectionHandler.new

# create the FastTestCase subclass
# module ActiveSupport
#   class FastTestCase < TestCase
#     def self.inherited(base)
#       TestFast.turn_on
#       begin
#         Site.first
#       rescue
#         ActiveRecord::Schema.verbose = false
#         require 'db/schema'
#         require 'db/seeds'
#       end
#       super
#     end

#     def setup
#       TestFast.turn_on
#       super
#     end

#     def teardown
#       super
#       TestFast.turn_off
#     end
#   end
# end

# ActiveSupport.on_load(:before_initialize) do
#   begin
#     Site.first
#   rescue
#     ActiveRecord::Schema.verbose = false
#     require 'db/schema'
#     require 'db/seeds'
#   end
# end

# The requires below were eliminated via the use of autoload_once_paths inside file_utils above
# but this is an example of the kind of dependencies we're dealing with in a single model class:

# add a sqlite3 connection to a separate connection pool called test_fast if it's not there already
# require 'active_record/connection_adapters/sqlite3_adapter'

# require 'active_model/errors_with_codes'
# require 'desk/hash_utils'
# require 'escargot'
# stub out elastic_index call
# Note that the following results in "unexpected invocation" errors on subclasses, known Mocha bug:
# ActiveRecord::Base.stubs(:elastic_index).returns(true)
# So I had to do it the Plain Ol' Ruby Object (PORO) way:
# class ActiveRecord::Base; def self.elastic_index(*args); true; end; end
# require 'config/environment'
# require 'config/application'
# require 'site_level'
# require 'site_status_type'
# require 'site_referral_type'
# require 'provisioning_provider_type'
# require 'assistly/acts_as_translatable'
# require 'email_template_type'
# require 'email_template'
# require 'active_record_common'
# require 'mailbox_password'
# require 'smtp_auth'
# require 'outbound_mailbox'
# require 'validations/html_safety'
# require 'web_template_type'
# require 'myportal_company_access'
# require 'portal_security_level'
# require 'login_remember_duration'
# require 'password_minimum_size'
# require 'captcha_options'
# require 'site_language_type'
# require 'user_level'
# require 'extensions/customer_authentication_extension'
# require 'bill_reward_type'
# require 'web_template'
# require 'site_config_type'

# require 'site'
# require 'retryable_when_stale'
# require 'desk/custom_data'
# require 'es_search/helper'
# require 'es_search/api_builder'
# require 'customer'
# require 'permissions'
# require 'ticket_filter_view_mode'
# require 'user_pref_type'
# require 'bill_payment_type'
# require 'bill_plan_type'
# require 'bill_reason_code'
# require 'bill_plan_component_type'
# require 'billing/bill_plan_component'
# require 'billing/bill_plan'
# require 'user'
