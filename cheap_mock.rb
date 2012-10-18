module CheapMock
  # ex. {Rails: {class_methods: {application: nil}}}
  def mockunmock(params={}, obj = Object, unmock = false)
    params.each do |key, value|
      case key
      when /\A[[:upper:]]/ # it's a class
        if unmock
          mockunmock(value, obj.const_get(key), unmock)
          obj.send(:remove_const, key)
        else
          klass = obj.const_set(key, Class.new)
          mockunmock(value, klass, unmock)
        end
      when /\Aclass_methods\Z/
        mockunmock(value, obj.singleton_class, unmock)
      when /\Ainstance_methods\Z/
        mockunmock(value, obj, unmock)
      else # it's a method
        if value.is_a? Hash # Problem with hash values though. :/
          mockunmock(value, obj, unmock)
        else
          if unmock
            obj.send(:remove_method, key)
          else
            obj.send(:define_method, key){ value }
          end
        end
      end
    end
  end
  def unmock(params={}, obj = Object)
    mockunmock(params, obj, true)
  end
  def mock(params={}, obj = Object)
    mockunmock(params, obj, false)
    if block_given?
      yield
      unmock(params, obj)
    end
  end
end

if __FILE__==$0
  require 'test/unit'
  class TestCheapMock < Test::Unit::TestCase
    include CheapMock
    MOCKS = {
      Rails: {
        class_methods: {
          application: 'hi!'
        },
        code: 'instance_value'
      },
      App: {
        AnotherClass: {
          imeth: 6
        }
      }
    }
    def test_mock_class_method
      mock(MOCKS) do
        assert_equal 'hi!', Rails.application
      end
      assert_raise(NameError){Rails}
      assert_raise(NameError){Rails.application}
    end
    def test_mock_class_hierarchy
      mock(MOCKS) do
        assert_equal "constant", defined?(App::AnotherClass)
      end
      assert_raise(NameError){App}
      assert_raise(NameError){App::AnotherClass}
    end
    def test_mock_instance_method
      mock(MOCKS) do
        assert_equal 'hi!', Rails.application
        assert_equal 'instance_value', Rails.new.code
        assert_equal 6, App::AnotherClass.new.imeth
      end
      assert_raise(NameError){Rails.application}
      assert_raise(NameError){App}
      assert_raise(NameError){App::AnotherClass}
    end
  end
end
