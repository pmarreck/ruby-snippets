class AddsUserToList
  RequiredArgumentsMissing = Class.new(StandardError)
  attr_reader :username, :user, :email_list_name, :creates_user, :notifies_user

  def initialize(params = {})
    set_ivars_from_params(params)
  end

  def call
    get_user
    notify_user
    update_user_with_list_name
  end

  private
  def set_ivars_from_params(params)
    @username        = params.fetch(:username){ raise RequiredArgumentsMissing, :username }
    @email_list_name = params.fetch(:email_list_name){ raise RequiredArgumentsMissing, :email_list_name }
    @creates_user    = params.fetch(:creates_user) { User }
    @notifies_user   = params.fetch(:notifies_user) { NotifiesUser }
  end
  def get_user
    @user = creates_user.find_or_create_by(username: username)
  end
  def notify_user
    notifies_user.(user, email_list_name)
  end
  def update_user_with_list_name
    user.update_attributes(email_list_name: email_list_name)
  end

end

if __FILE__==$PROGRAM_NAME
  require 'test/unit'
  require 'mocha/setup'

  class AddsUserToListTest < Test::Unit::TestCase

    def setup
      @creates_user  = stub
      @notifies_user = stub
      @user          = stub
      @adds_user_to_list = AddsUserToList
      @subject = @adds_user_to_list.new(username: 'username', email_list_name: 'list_name',
        creates_user: @creates_user, notifies_user: @notifies_user)
    end

    def test_register_a_new_user
      @creates_user.expects(:find_or_create_by).with(username: 'username').returns(@user)
      @notifies_user.expects(:call).with(@user, 'list_name')
      @user.expects(:update_attributes).with(email_list_name: 'list_name')
      @subject.call
    end

    def test_missing_username_blows_up
      assert_raise(::AddsUserToList::RequiredArgumentsMissing){ @adds_user_to_list.new(email_list_name: 'a') }
    end

    def test_missing_email_list_name_blows_up
      assert_raise(::AddsUserToList::RequiredArgumentsMissing){ @adds_user_to_list.new(username: 'a') }
    end

  end

end
