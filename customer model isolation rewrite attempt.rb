require './abstract_class_dependency'

class Customer < (module ActiveRecord; class Base; self; end; end)
  include AbstractClassDependency

  depends_on_modules %w[
    NewRelic::Agent::MethodTracer
    Desk::CustomData
    Assistly::RetryableWhenStale
    EsSearch::Helper::InstanceMethods
    ActiveRecord
    Rails
  ]

  depends_on_classes %w[
    CustomField
    CustomerContactType
    SiteLanguageType
    CustomerCompanyLink
    CustomerDrop
    CustomerContactEmail
    Customer
    I18n
    Email
    Interaction
    InteractionBasis
    InteractionType
    Ticket
    MyportalCompanyAccess
    DateTime
    Time
    WillPaginate::Collection
  ]

  depends_on_constant ->{ rails_module.application.routes.url_helpers },
    as: :rails_routes_url_helpers

  include_deferred(
    :newrelic__agent__methodtracer_module,
    :rails_routes_url_helpers,
    :assistly__retryable_when_stale_module,
    :desk__custom_data_module
  )

  extend_deferred(
    :es_search__helper__instance_methods_module
  )

  class TooManyEmailAddresses < StandardError; end

  CUSTOM_FIELDS_LIMIT = 25

  setup_class do
    acts_as_paranoid
    validate :validate_required_interaction_type
    validate :validate_custom_fields, :if => :changed?

    before_validation :link_twitter_user, :if => proc { |c| c.twitter_user }
    before_save :before_save_customer
    before_save :mark_for_indexing
    before_create :reset_ticket_count

    after_save :set_company_from_new_company_name

    belongs_to :site
    belongs_to :user, :touch => true
    belongs_to :lockable, :polymorphic => true
    belongs_to :default_address, :class_name => 'CustomerContactAddress'
    belongs_to :default_email, :class_name => 'CustomerContactEmail'
    belongs_to :default_phone, :class_name => 'CustomerContactPhone'
    belongs_to :last_saved_by, :class_name => 'User'
    belongs_to_enum :site_language_type

    has_one :twitter_user, :inverse_of => :customer
    has_one :facebook_user
    has_one :identity, :foreign_key => 'owner_id', :dependent => :destroy

    has_many :tickets
    has_many :ticket_customers
    has_many :qnas

    has_many :customer_contact_addresses, :inverse_of => :customer
    has_many :customer_contact_emails, :inverse_of => :customer
    has_many :customer_contact_phones, :inverse_of => :customer

    has_one :customer_company_link, :inverse_of => :customer
    has_many :authentications, :as => :authenticatable, :dependent => :destroy

    attr_accessor :current_user

    scope :since_id, lambda { |id| return {} if id.blank?; {:conditions =>["id > ?",id.to_i] } }
    scope :max_id, lambda { |id| return {} if id.blank?; {:conditions =>["id <= ?",id.to_i] } }
    scope :since_created_at, lambda { |t| return {} if t.blank?; {:conditions =>["created_at > ?",time_class.at(t.to_i)] } }
    scope :max_created_at, lambda { |t| return {} if t.blank?; {:conditions =>["created_at <= ?",time_class.at(t.to_i)] } }
    scope :since_updated_at, lambda { |t| return {} if t.blank?; {:conditions =>["updated_at > ?",time_class.at(t.to_i)] } }
    scope :max_updated_at, lambda { |t| return {} if t.blank?; {:conditions =>["updated_at <= ?",time_class.at(t.to_i)] } }
    scope :not_in, lambda { |ids| return {} if ids.empty?; { :conditions => ["id NOT IN (?)",ids.join(",")] } }
    scope :expired_locked_until, lambda { where("customers.locked_until < ?", time_class.now) }

    accepts_nested_attributes_for :user, :allow_destroy => true, :reject_if => :all_blank
    accepts_nested_attributes_for :twitter_user, :allow_destroy => true, :reject_if => :all_blank
    accepts_nested_attributes_for :customer_contact_emails, :allow_destroy => true, :reject_if => :all_blank
    accepts_nested_attributes_for :customer_contact_phones, :allow_destroy => true, :reject_if => :all_blank
    accepts_nested_attributes_for :customer_contact_addresses, :allow_destroy => true, :reject_if => :all_blank

    # Define proxy methods for custom types
    (1..CUSTOM_FIELDS_LIMIT).each do |index|
      define_method("custom#{index}_convert") { custom_field_value_conv(index, self.site) }
    end

    # Define setters
    (1..CUSTOM_FIELDS_LIMIT).each do |index|
      define_method("custom#{index}=") do |value|
        begin
          field = custom_field_class.find_field(:customer, index, self.site)
          if field && field.custom_field_data_type == :date
            self["custom#{index}"] = date_time_class.strptime(value, "%m/%d/%Y").to_i.to_s rescue value
          elsif field && field.custom_field_data_type == :integer
            self["custom#{index}"] = value.to_s
          else
            self["custom#{index}"] = value.to_s
          end
        rescue
          self["custom#{index}"] = value
        end
      end
    end

    elastic_index :versioned => true, :version_column => 'lock_version', :mapping => {
      :dynamic        => false,
      :_source        => {:enabled => false},
      :_routing       => {:required => true, :path => "site_id"},
      :include_in_all => true,
      :properties => {
        :id                   => {:type => "long", :include_in_all => false},
        :customer_first_name  => {:type => "string"},
        :customer_last_name   => {:type => "string"},
        :customer_name        => {:type => "string"},
        :customer_company     => {:type => "string"},
        :customer_email       => {:type => "multi_field", :fields => {:customer_email => {:type => "string"}, :standard => {:type => "string", :analyzer => "standard", :include_in_all => true}}},
        :customer_phone       => {:type => "string"},
        :customer_address     => {:type => "string"},
        :customer_custom1     => {:type => "string"},
        :customer_custom2     => {:type => "string"},
        :customer_custom3     => {:type => "string"},
        :customer_custom4     => {:type => "string"},
        :customer_custom5     => {:type => "string"},
        :customer_custom6     => {:type => "string"},
        :customer_custom7     => {:type => "string"},
        :customer_custom8     => {:type => "string"},
        :customer_custom9     => {:type => "string"},
        :customer_custom10    => {:type => "string"},
        :customer_custom11    => {:type => "string"},
        :customer_custom12    => {:type => "string"},
        :customer_custom13    => {:type => "string"},
        :customer_custom14    => {:type => "string"},
        :customer_custom15    => {:type => "string"},
        :customer_custom16    => {:type => "string"},
        :customer_custom17    => {:type => "string"},
        :customer_custom18    => {:type => "string"},
        :customer_custom19    => {:type => "string"},
        :customer_custom20    => {:type => "string"},
        :customer_custom21    => {:type => "string"},
        :customer_custom22    => {:type => "string"},
        :customer_custom23    => {:type => "string"},
        :customer_custom24    => {:type => "string"},
        :customer_custom25    => {:type => "string"},
        :twitter_user         => {:type => "string"},
        :site_id              => {:type => "long", :include_in_all => false},
        :external_id          => {:type => "long", :include_in_all => false},
        :created_at           => {:type => "long", :include_in_all => false},
        :updated_at           => {:type => "long", :include_in_all => false}
      }
    }
    add_method_tracer :company_association,
      'Custom/Customer/company_association'

    add_method_tracer :set_company_from_name,
      'Custom/Customer/set_company_from_name'

    add_method_tracer :verified_ticket_find,
      'Custom/Customer/Portal/verified_ticket_find'

    add_method_tracer :verified_tickets_by_page,
      'Custom/Customer/Portal/verified_tickets_by_page'

  end # setup_class

  def indexed_json_document
    {
      :id                   => self.id,
      :customer_first_name  => (self.first_name.nil? ? '' : self.first_name),
      :customer_last_name   => (self.last_name.nil? ? '' : self.last_name),
      :customer_name        => (self.name.nil? ? '' : self.name),
      :customer_company     => self.legacy_company_name.to_s,
      :customer_email       => self.emails.split(","),
      :customer_phone       => self.phones.split(","),
      :customer_address     => self.addresses,
      :customer_custom1     => (self.custom1.nil? ? '' : self.custom1),
      :customer_custom2     => (self.custom2.nil? ? '' : self.custom2),
      :customer_custom3     => (self.custom3.nil? ? '' : self.custom3),
      :customer_custom4     => (self.custom4.nil? ? '' : self.custom4),
      :customer_custom5     => (self.custom5.nil? ? '' : self.custom5),
      :customer_custom6     => (self.custom6.nil? ? '' : self.custom6),
      :customer_custom7     => (self.custom7.nil? ? '' : self.custom7),
      :customer_custom8     => (self.custom8.nil? ? '' : self.custom8),
      :customer_custom9     => (self.custom9.nil? ? '' : self.custom9),
      :customer_custom10    => (self.custom10.nil? ? '' : self.custom10),
      :customer_custom11    => (self.custom11.nil? ? '' : self.custom11),
      :customer_custom12    => (self.custom12.nil? ? '' : self.custom12),
      :customer_custom13    => (self.custom13.nil? ? '' : self.custom13),
      :customer_custom14    => (self.custom14.nil? ? '' : self.custom14),
      :customer_custom15    => (self.custom15.nil? ? '' : self.custom15),
      :customer_custom16    => (self.custom16.nil? ? '' : self.custom16),
      :customer_custom17    => (self.custom17.nil? ? '' : self.custom17),
      :customer_custom18    => (self.custom18.nil? ? '' : self.custom18),
      :customer_custom19    => (self.custom19.nil? ? '' : self.custom19),
      :customer_custom20    => (self.custom20.nil? ? '' : self.custom20),
      :customer_custom21    => (self.custom21.nil? ? '' : self.custom21),
      :customer_custom22    => (self.custom22.nil? ? '' : self.custom22),
      :customer_custom23    => (self.custom23.nil? ? '' : self.custom23),
      :customer_custom24    => (self.custom24.nil? ? '' : self.custom24),
      :customer_custom25    => (self.custom25.nil? ? '' : self.custom25),
      :twitter_user         => (self.cached_twitter_user && self.cached_twitter_user.login? ? self.cached_twitter_user.login : ''),
      :site_id              => self.site_id,
      :external_id          => (self.external_id.nil? ? nil : self.external_id.to_i),
      :created_at           => (self.created_at.nil? ? nil : self.created_at.to_i),
      :updated_at           => (self.updated_at.nil? ? nil : self.updated_at.to_i)
    }
  end

  # fields to restrict query string searches from searching all fields
  def self.es_query_fields
    fields = %w{customer_first_name customer_last_name customer_name customer_company customer_email customer_phone}
    (1..CUSTOM_FIELDS_LIMIT).each do |i|
      fields << "customer_custom#{i}"
    end
    fields << %w{twitter_user customer_address}
  end

  def self.find_id_by_verified_email(email, site)
    if email = site.customer_contact_emails.verified.select(:customer_id).find_by_email(email)
      email.customer_id
    end
  end

  # Should find customer based on authentication provider.  For example, search twitter_user when provided with twitter info
  def self.from_omniauth(site, auth_hash, email)

    if email.respond_to?(:email)
      cce = email
    else
      cce = site.customer_contact_emails.find_or_initialize_by_email(email) do |email|
        email.customer_contact_type = customer_contact_type_class[:home]
      end
    end

    customer = if ["facebook", "twitter"].include? auth_hash['provider']
      external_id_class = "#{auth_hash['provider']}_user".camelcase.constantize
      external_id = external_id_class.find_or_build_from_omniauth(site, auth_hash, cce)

      if external_id && self.can_use_for_authentication?(external_id, cce)
        external_id.save
        external_id.customer
      else
        nil
      end
    else
      cce.customer
    end

    if customer && cce
      if auth_hash['provider'] == 'identity'
        cce.isolate_and_verify!
      else
        cce.customer = customer
        cce.verify!
      end
    end

    customer
  end

  def self.can_use_for_authentication?(provider, email)
    !provider.persisted? ||
    (!provider.customer.verified? && (email.nil? || (email.customer == provider.customer) || !email.verified?))
  end

  def update_from_omniauth(auth_hash)
    ["name", "first_name", "last_name"].each do |attr|
      self.send("#{attr}=", auth_hash["info"][attr]) if auth_hash["info"][attr]
    end

    save
  end

  def self.create_guest(site)
    site.customers.create(name: i18n_class.t("common.guest"))
  end

  def mark_for_indexing
    unless self.marked_for_indexing
      self.marked_for_indexing = (self.changed? && !(self.changed.sort == ["lockable_id", "lockable_type"]) && !(self.changed == ["customer_merge_id"]) &&
        !(self.changed.sort == ["lockable_id", "lockable_type", "locked_until"]))
    end
    return true
  end

  def as_json(options={})


    customer_language = nil
    customer_language = site_language_type_class[self.site_language_type_id].iso_language_code if true == self.site.multi_lang_enabled_config && !self.site_language_type_id.nil?

    customer = {:customer=>
                {
                  :id=>self.id,
                  :first_name=>self.first_name,
                  :last_name=>self.last_name,
                  :emails=>self.customer_contact_emails,
                  :phones=>self.customer_contact_phones,
                  :addresses=>self.customer_contact_addresses,
                  :twitters=>[self.twitter_user],
                  :language=>customer_language
                }
                }

    site.custom_customer_fields.each do |custom_field|
      customer[:customer]["custom_#{custom_field.name}"] = self["custom#{custom_field.custom_field_index}".to_sym]
    end

    customer
  end

  def to_liquid
    @liquid ||= customer_drop_class.new(self).to_liquid
  end

  # Returns all attributes that can conflict and need resolution
  def self.conflicting_attributes
    attrs = [:first_name, :last_name, :company, :title, :desc, :external_id, :site_language_type_id]
    attrs += customer_class.column_names.find_all { |c| c =~ /custom\d+/ }.collect(&:to_sym)
  end

  ############
  ## BIZ RULES
  def emails
    if self.customer_contact_emails_count > 0
      self.customer_contact_emails.collect{|x| x.email}.join(",")
    else
      ""
    end
  end

  def phones
    if self.customer_contact_phones_count > 0
      self.customer_contact_phones.collect{|x| x.phone.to_s}.join(",")
    else
      ""
    end
  end

  def addresses
    if self.customer_contact_addresses_count > 0
      self.customer_contact_addresses.collect{|x| x.location}.join(",")
    else
      ""
    end
  end
  ## BIZ RULES
  ############

  def self.max_number_emails_addresses
    10
  end

  def is_user?
    !self.user.nil?
  end

  def name

    val = (self.first_name.nil? ? "" : self.first_name)
    val += (self.last_name.nil? ? "" : " #{self.last_name}")

    val = val.strip

    val = i18n_class.translate("case.customer.name_empty") if val.empty?

    val
  end

  def name_blank?
    self.first_name.blank? && self.last_name.blank?
  end

  def name_plain
    self.name
  end

  def name= val
    parts = val.split(',')

    self.first_name = val.strip()
    self.last_name = ""
    if parts.length>1
      self.last_name = parts[0].strip()
      self.first_name = parts[1].strip()
    else
      parts = name.split(' ')

      if parts.length>1
        self.first_name = parts[0].strip()
        self.last_name = parts[1..parts.length].join(' ').strip()
      end
    end
  end

  def email
    obj = default_email
    obj.email unless obj.nil?
  end

  def email_domain
    if e = email
      e.split("@").last
    end
  end

  def email_domains
    self.customer_contact_emails.map(&:email).collect do |e|
      e.split("@").last
    end
  end

  def phone
    obj = default_phone
    obj.phone unless obj.nil?
  end

  def address
    obj = default_address
    obj.location unless obj.nil?
  end


  # Overriding associations is bad
  # Hate not being able to remove it
  # Will require major refactoring
  def default_email
    return unless customer_contact_emails_count > 0

    if default_email_id
      self.customer_contact_emails.find_by_id(default_email_id)
    else
      self.customer_contact_emails.recently_verified.first
    end
  end

  def default_phone
    if self[:default_phone].nil?
      (self.customer_contact_phones_count > 0) ? self.customer_contact_phones.first : nil
    else
      self[:default_phone]
    end
  end

  def default_address
    if self[:default_address].nil?
      (self.customer_contact_addresses_count > 0) ? self.customer_contact_addresses.first : nil
    else
      self[:default_address]
    end
  end

  # Add new phone number to customer and use as default if it's the first.
  def add_new_phonenum(phonenum)
    self.customer_contact_phones.build({
                                         :phone=>phonenum,
                                         :customer_contact_type=>customer_contact_type_class[:home]
    }) unless self.customer_contact_phones.find_by_phone(phonenum)
  end


  def cached_twitter_user
    #workaround marshal dump issue with caching facebook user and twitter user.
    return nil unless self.has_twitter_user?
    self.twitter_user
  end

  def cached_facebook_user
    #workaround marshal dump issue with caching facebook user and twitter user.
    return nil unless self.has_facebook_user?
    self.facebook_user
  end

  ## (JS - 2010.05) We use this to tell our model that we are requiring a specific contact type when saving
  def required_interaction_type_id= value
    @required_interaction_type_id= value.to_i
  end

  def self.strip_name_of_quotes(text)
    return "" if text.blank?
    temp = text[/\A\"(.*)\"\z/m,1]
    return temp unless temp.nil?
    return text
  end

  def has_twitter_user?
    self.twitter_users_count > 0
  end

  def has_facebook_user?
    self.facebook_users_count > 0
  end

  def self.get_by_email(site_id, emails, customer_name=nil, site_language_type_id = nil)

    emails = emails.compact
    return nil if emails.blank? #you need at least one email to call this method, otherwise just create a customer record yourself

    customer_contact_email = nil
    addresses = emails.collect{|email| email_class.address_mash(email) }.delete_if{|x| x.email.nil? || !email_class.valid?(x.email) }
    uniq_emails = email_class.clean_addresses_array(emails.join(", "))

    uniq_emails.each do |email|
      customer_contact_email = customer_contact_email_class.find_by_site_id_and_email_puny(site_id, email)
      break unless customer_contact_email.nil?
    end

    if customer_contact_email.nil?
      #none of the emails passed in matched, so create a customer and add all emails to record.
      return nil if addresses.empty? #do not create a customer record if a valid email isn't passed into this method

      name = customer_name || addresses[0].name
      name = addresses[0].local if name.blank?
      name = customer_class.strip_name_of_quotes(name)

      @customer = customer_class.new({:name=>name, :site_language_type_id =>site_language_type_id})
      @customer.site_id = site_id
      uniq_emails.each do |email|
        cce = @customer.customer_contact_emails.new({ :email=>email, :customer_contact_type_id=>customer_contact_type_class[:home].id })
        cce.site_id = site_id
        @customer.customer_contact_emails << cce if cce.valid?
      end

      return nil if @customer.customer_contact_emails.empty? #do not create a customer record if a valid email isn't passed into this method

      @customer.save!

    else
      #one of the emails was found, make sure the others are added if they do not already exist in the system.
      @customer = customer_contact_email.customer
      @customer.site_language_type_id = site_language_type_id unless @customer.site_language_type_id

      uniq_emails.each do |email|
        customer_contact_email = customer_contact_email_class.find_by_site_id_and_email_puny(site_id, email)
        if customer_contact_email.nil? #not found, then add to this customer
          cce = @customer.customer_contact_emails.new({:email=>email, :customer_contact_type_id=>customer_contact_type_class[:home].id })
          cce.site_id = site_id
          @customer.customer_contact_emails << cce if cce.valid?
        end
      end

      @customer.save! if @customer.changed?
    end

    return @customer.try(:reload)
  end

  def add_email(email, dosave=true)
    cce = customer_contact_email_class.new({ :email=>email, :customer_contact_type_id=>customer_contact_type_class[:home].id })
    cce.site_id = self.site_id
    self.customer_contact_emails << cce
    self.default_email=self.customer_contact_emails.first || cce if self.default_email.nil?
    self.updated_at = time_class.now
    self.save! if dosave
  end

  def test_email(subject, body)
    @webform = email_class.new({:site_id=>self.site_id, :subject=>subject,:body=>body})

    @interaction= interaction_class.new({:site_id=>self.site_id,
                                   :interaction_type=> :email,
                                   :interactionable=>@webform})

    @interaction.ticket = ticket_class.new({:site_id=>self.site_id,
                                      :customer_id=>self.id,
                                      :subject=>subject,
                                      :interaction_type=> :email,
                                      :display_id => Site.increment_display_id(self.site_id)})

    @webform.ticket = @interaction.ticket

    @interaction.save
  end

  def lock_to(owner, lock_until = nil)
    if lockable == owner # Already obtain lock
      true
    elsif lockable.nil?
      self.lockable = owner
      self.locked_until = lock_until if lock_until
      self.save
    end
  rescue active_record_module::StaleObjectError
    self.lockable = nil
    return false
  end

  def unlock_from(owner)
    if lockable == owner
      self.lockable = nil
      self.locked_until = nil
      self.save
    end
  rescue active_record_module::StaleObjectError
    self.lockable = owner
    return false
  end

  def locked?
    !self.locked_until.nil?
  end

  # Searches potential duplicates
  # TODO: Remove .compact and search non deleted customers when we are properly indexing deleted_at
  def potential_duplicates(options = {})
    options[:index] = customer_class.elastic_search_site_alias(site_id)
    customer_class.search_es({
                         :query => {
                           :bool => {
                             :must => [
                               { :term => { :site_id => site_id } },
                               { :query_string => { :query => "customer_name:#{name}".es_escape }}
                             ],
                             :must_not => {
                               :term => { :id => id }
                             }
                           }
                         }
    }, options)
  end

  def site_language_type_id_by_rule=(val)
    self.site_language_type_id = val  if self.site.multi_lang_enabled_config
  end

  def parent_site_language_type_id
    return 0 unless self.site_language_type_id
    site_language_type_class[self.site_language_type_id].parent
  end

  def ticket_history(page, per_page)
    will_paginate__collection_class.create(page, per_page, nil) do |pager|
      # MySQL Optimization: late row lookups
      # http://explainextended.com/2009/10/23/mysql-order-by-limit-performance-late-row-lookups/
      query = "SELECT t.* FROM (SELECT id FROM tickets WHERE (customer_id = ?) ORDER BY id DESC LIMIT ? OFFSET ?) q JOIN tickets t ON t.id = q.id"
      pager.replace ticket_class.find_by_sql([query, self.id, pager.per_page, pager.offset])
      # likely similar but maybe 1.8x slower:
      # pager.replace Ticket.unscoped.where(id: Ticket.where(customer_id: self.id).select(:id).limit(per_page).offset(page).map(&:id)).order('id DESC')
      pager.total_entries = self.tickets_count # force total_entries to be cached ticket_count
    end
  end

  # Public: Check whether this customer is linked to a company.
  #
  # Use this to avoid going through the .company association and thus
  # instantiating an entire ActiveRecord instance.
  #
  # Returns true or false.
  def has_company?
    unless new_record?
      customer_company_link_class.where(customer_id: id).exists?
    end
  end

  def company=(company_name)
    @new_company_name = company_name
  end

  def company_association
    if self.legacy_company_name
      migrate_legacy_company_name
    end

    customer_company_link.try(:company)
  end

  # Return the company name rather than the company object for backwards-
  # compatibility reasons.
  def company
    @new_company_name || company_association.try(:name)
  end

  def tickets_count
    unless ticket_count
      return self.tickets.count
    end

    ticket_count
  end

  def coworker_ids
    customer_company_link_class.select(:customer_id).
                      where(site_id: site_id,
                            company_id: customer_company_link.company_id).
                      collect(&:customer_id)
  end

  # Queries for a ticket base on customer's verified status.
  # Only returns ticket originating from verified email addresses
  # Twitter and Facebook channels are filtered until a verify concept exists
  #
  # Returns ticket
  def verified_ticket_find(params)
    ticket = nil
    ticket = begin # TODO: Is it worth caching here???
      query = ticket_class.joins(:interactions)
                    .joins("JOIN `customer_contact_emails` ON
                            `customer_contact_emails`.customer_id = `tickets`.customer_id AND
                            `customer_contact_emails`.email = `interactions`.email AND
                            `customer_contact_emails`.verified_at IS NOT null")
                    .where(
                      interactions:{
                        interaction_basis_id: interaction_basis_class[:original].id
                      },
                      site_id: self.site_id)
                    .where(params)
                    .emails

      if self.can_access_company_tickets?
        query = query.where("`tickets`.`customer_id` IN (#{coworker_ids.join(",")})")
      else
        query = query.where("`tickets`.`customer_id` = ?", self.id)
      end
      query.first
    end
    ticket
  end

  # Queries for tickets base on customer's verified status.
  # Only returns tickets originating from verified email addresses
  # Twitter and Facebook channels are filtered until a verify concept exists
  #
  # Returns tickets for page
  def verified_tickets_by_page(page_number, search_params={})
    tickets = nil
    begin
      page_number = 1 unless page_number.to_s.is_numeric?
      tickets = begin # TODO: Is it worth caching here???
        query = ticket_class.joins(:interactions)
                      .joins("JOIN `customer_contact_emails` ON
                              `customer_contact_emails`.`customer_id` = `tickets`.`customer_id` AND
                              `customer_contact_emails`.`email` = `interactions`.`email` AND
                              `customer_contact_emails`.`verified_at` IS NOT null")
                      .where(
                        interactions:{
                          interaction_basis_id: interaction_basis_class[:original].id
                        },
                        site_id: self.site_id)
                      .where("`tickets`.`message_count` IS NOT NULL")
                      .emails

        if search_params[:company] && self.can_access_company_tickets?
          query = query.where("`tickets`.`customer_id` IN (#{coworker_ids.join(",")})")
        else
          query = query.where("`tickets`.`customer_id` = ?", self.id)
        end

        query = query.where("`tickets`.`created_at` > ?",
                            search_params[:days].to_i.days.ago) unless search_params[:days].blank?
        query = query.not_resolved_or_closed if search_params[:active] == "1"
        query = query.reorder("`tickets`.`created_at` desc").paginate(page: page_number,
                              per_page: configatron.myportal.cases.page_size).all
      end
    rescue RangeError => exception
      unless page_number == 1
        page_number = 1
        retry
      end
    end
    tickets
  end

  def authenticated?
    authentications.exists?
  end

  def guest?
    !authenticated?
  end

  def can_access_company_tickets?
    self.has_company? &&
    self.site.portal_web_template_myportal_companies_config && (
      ( self.site.portal_web_template_myportal_company_access_config.to_i ==
            myportal_company_access_class[:authorized_only].id &&
          self.myportal_company_access ) ||
      self.site.portal_web_template_myportal_company_access_config.to_i ==
        myportal_company_access_class[:all].id
    )
  end

  def set_company_from_name(name)
    new_company = site.companies.where(name: name).first

    unless new_company
      new_company = site.companies.build(name: name)
      new_company.save
    end

    customer_company_link.try(:destroy)
    new_company.add_customer(self)

    clear_association_cache
    true
  end

  def verified?
    customer_contact_emails.verified.any?
  end

  def unverify!
    self.class.transaction do
      customer_contact_emails.verified.each do |email|
        email.update_attribute(:verified_at, nil)
      end
      identity.destroy if identity
      authentications.each {|a| a.destroy }
    end
  end

private

  def migrate_legacy_company_name
    self.class.transaction do
      set_company_from_name(self.legacy_company_name)
      update_attribute :legacy_company_name, nil
    end

    clear_association_cache
    true
  end

  def set_company_from_new_company_name
    if @new_company_name
      set_company_from_name @new_company_name
      @new_company_name = nil
    end; true
  end

  def validate_required_interaction_type
    if @required_interaction_type_id
      case @required_interaction_type_id
      when interaction_type_class[:email].id
        errors.add(:base, i18n_class.t("agent.email.validation.error_required")) if self.customer_contact_emails.empty?
      when interaction_type_class[:twitter].id
        errors.add :twitter_user, i18n_class.t("agent.twitter.validation.error_required") if self.twitter_user.nil? || self.twitter_user.login.blank?
      end
    end
  end

  def validate_custom_fields
    site.custom_customer_fields.each do |custom_field|
      if self.send("custom#{custom_field.custom_field_index}_changed?")
        unless custom_field.validate_value(self["custom#{custom_field.custom_field_index}"])
          errors.add("custom#{custom_field.custom_field_index}", i18n_class.t("activerecord.errors.messages.invalid", :attribute => custom_field.name))
        end
      end
    end
  end

  def link_twitter_user
    self.twitter_user.link_customer(self) if !self.twitter_user.login.blank? && self.twitter_user.id.nil?
    self.updated_at = time_class.now if self.twitter_user.changed?
    self.twitter_user = nil if self.twitter_user.login.blank?
    true
  end

  def before_save_customer

    raise customer_class::TooManyEmailAddresses if self.customer_contact_emails.size > customer_class.max_number_emails_addresses

    if (self.user_id && (self.first_name_changed? || self.last_name_changed?))
      self.user.name = self.name.strip
      self.user.name_public = self.user.name
    end

    self.name = i18n_class.t("interaction.chat.name_empty") if self.name.empty?
    true
  end

  def reset_ticket_count
    self.ticket_count = 0
  end

end

if __FILE__==$PROGRAM_NAME
  require 'test/unit'
  class IndependenceTest < Test::Unit::TestCase

    module SubjectExtendStubs
      def acts_as_paranoid(*args); true; end
      def validate(*args); true; end
      def before_validation(*args); true; end
      def before_save(*args); true; end
      def before_create(*args); true; end
      def after_save(*args); true; end
      def belongs_to(*args); true; end
      def belongs_to_enum(*args); true; end
      def has_one(*args); true; end
      def has_many(*args); true; end
      def scope(*args); true; end
      def accepts_nested_attributes_for(*args); true; end
      def elastic_index(*args); true; end
      def add_method_tracer(*args); true; end

      def run_extends(*args); true; end
    end

    module SubjectIncludeStubs
      def run_includes(*args); true; end
    end

    def subject
      Customer
    end

    def stub_macro_methods(o = subject, mm = SubjectExtendStubs)
      o.extend mm
    end

    def stub_module_inclusion_and_extension(o = subject)
      o.send(:include, SubjectIncludeStubs)
    end

    def setup_dependency_removal
      # stub_class_setup
      stub_module_inclusion_and_extension
      stub_macro_methods
    end

    def test_for_independent_class_load
      assert true #would have failed already
    end

    def test_for_independence
      setup_dependency_removal
      c = subject.new
      assert c
      assert_equal Customer, c.class
      assert_equal [Customer,
        IndependenceTest::SubjectIncludeStubs,
        AbstractClassDependency::InstanceMethods,
        AbstractClassDependency,
        ActiveRecord::Base,
        Object,
        PP::ObjectMixin,
        Kernel,
        BasicObject], c.class.ancestors
    end

  end
end
