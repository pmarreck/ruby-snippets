
# stub the shit out of a view to test a view helper method

require 'active_support/core_ext/string/encoding'
require 'active_support/all'
require 'action_view'
require 'action_view/context'
require 'action_view/template'
require 'action_view/helpers'
require 'action_view/helpers/form_helper'
require 'active_record'

# ActionView::Template::Handlers::ERB

# This is a working stubbed-out model that in theory won't touch the database.
class TestModel < ActiveRecord::Base
  def self.primary_key; @primary_key ||= 'id'; end
  def self.columns; @columns ||= [ActiveRecord::ConnectionAdapters::Column.new('id',0,'numeric')]; end
  def self.columns_hash; Hash[self.columns.map { |c| [c.name, c] }]; end
  def self.column_defaults; @column_defaults ||= {'id' => 0}; end
  def inspect; "#{self.class}(#{self.class.columns.map { |c| "#{c.name}: #{c.type}" } * ', '})"; end
end
# TestModel.new
# render_erb = ->(string) do
#   ActionView::Template.new(
#   string.strip,
#   "test template",
#   ActionView::Template::Handlers::ERB,
#   {}).render(self, {}).strip
# end
# puts render_erb.call('<%= form_for TestModel.new {|f| f.submit } %>')
module ActionView
  class Template
    include ActionView::Helpers::FormTagHelper
  end
end
template = ActionView::Template.new('', "test template", ActionView::Template::Handlers::ERB, {})
submit_tag = ActionView::Helpers::FormBuilder.new('test_model', TestModel.new, template, {}, nil).submit
assert (submit_tag =~ /id="test_model_submit"/)
puts submit_tag