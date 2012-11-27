module ObjectUtils

  IMMEDIATE_VALUE_CLASSES = [Numeric, Symbol, TrueClass, FalseClass, NilClass]

  # default simplified representation/inspection for all objects
  def to_h
    h = {}
    if self.class.respond_to? :attributes
      attrs = self.class.attributes
      attrs.each{|att| h.store(att, self.send(att))}
    elsif self.respond_to?(:instance_variables) && !self.instance_variables.empty?
      attrs = self.instance_variables
      attrs.each{|att| h[att.to_s.delete("@")] = instance_variable_get(att) }
    elsif self.class == Class
      h[:class] = self.inspect_without_obj_id
    elsif self.respond_to? :inspect
      # remove __id__ info, which is actually the C (void *) to the obj in memory... TMI
      h[:data] = self.inspect_without_obj_id
    else # ok this object is weird. Liquid::Strainer was one of these wiseguys.
      h[:data] = self.class.to_s
    end
    h.delete_if {|k,v| v.respond_to?(:nil?) ? v.nil? : false}
    h
  end

  def inspect_without_obj_id
    # remove __id__ info, which is actually the C (void *) to the obj in memory... TMI
    # This was meant to help spurious diffs of objects which only had the object_id change
    # due to reinstantiation/dup/cloning
    self.inspect.gsub(/\:0x[0-9a-f]+/,'')
  end

  OBJECT_REPRESENTATION_DEFAULTS = {
      include_backreferences: false, # yaml-style backreference output
      symbolize_keys:         false,
      as_json:                false, # will tend to use json-style object serialization
      maxdepth:               25,
      prune:                  ->(*a){true} # a block taking a or k,v that filters what is represented
  }

  # Represent: Get a Ruby object representation (nested hash typically)
  # of any Ruby object of any complexity, to maxdepth, that only uses
  # the basic Ruby classes.
  # Ideal for passing output into to_json or to_yaml (which choke on anything complex).
  # I toyed with calling this "serialize" but it was interacting oddly with other
  # "serialize" methods in random objects in the hierarchy. Also, since there's
  # currently no deserialization, it's not a true serialize.
  def represent(opts={}, maxdepth=nil)
    opts = OBJECT_REPRESENTATION_DEFAULTS.merge(opts)
    maxdepth ||= opts[:maxdepth]
    maxdepth -= 1
    opts[:already_represented_object_ids] ||= {}
    aroids = opts[:already_represented_object_ids] # way shorter handle on it.
    if maxdepth > 0
      o = nil
      unless aroids[self.object_id]
        a_kind = self.respond_to?(:kind_of?)
        basic_obj = IMMEDIATE_VALUE_CLASSES.any?{|c| a_kind && self.kind_of?(c)}
        if basic_obj
          o = self
        elsif a_kind && self.kind_of?(String)
          o = self.dup
        elsif a_kind && self.kind_of?(Date) # also accounts for DateTime objects FYI
          o = self.iso8601
        elsif a_kind && self.kind_of?(Time)
          o = self.utc.iso8601 # same as ActiveSupport.use_json_time_format = true, but without the dependency
        elsif a_kind && self.kind_of?(Class)
          if opts[:as_json]
            # this depends on ActiveSupport
            o = self.to_s.underscore
          else
            if opts[:symbolize_keys] && !opts[:stringify_keys]
              o = self.to_s.to_sym
            else
              o = self.to_s
            end
          end
        elsif a_kind && self.kind_of?(Hash)
          interim_hash = {}
          aroids[self.object_id] = interim_hash.object_id
          o = self.select(&opts[:prune]).inject(interim_hash) do |h,(k,v)|
            h[k.represent(opts, maxdepth+1)] = v.represent(opts, maxdepth)
            h
          end
          if opts[:symbolize_keys] || opts[:stringify_keys]
            if opts[:symbolize_keys]
              o = o.symbolize_keys
            elsif opts[:stringify_keys]
              o = o.stringify_keys
            end
            aroids[self.object_id] = o.object_id
          end
        elsif a_kind && self.kind_of?(Array)
          o = []
          aroids[self.object_id] = o.object_id
          o.replace(self.map{|e| e.represent(opts, maxdepth)})
        else # this is an unknown object
          if self.respond_to? :to_hash
            h = self.to_hash
          else
            h = self.to_h
          end
          h.select!(&opts[:prune])
          o = h.represent(opts, maxdepth)
          o = o[:data] if o[:data]
          o = o['data'] if o['data']
          if opts[:as_json]
            # this depends on ActiveSupport
            o = {self.class.to_s.underscore => o}
          else
            if opts[:symbolize_keys] && !opts[:stringify_keys]
              o = {self.class.to_s.to_sym => o}
            else
              o = {self.class.to_s => o}
            end
          end
          aroids[self.object_id] = o.object_id
        end
      else # this object has already been represented.
        if opts[:include_backreferences]
          # add a "yaml-esque" backreference
          which = aroids.keys.index(self.object_id)
          stamp = "id#{'%03d' % (which+1)}"
          # add the reference to the original object
          # This is why we were tracking object_id's all over the place earlier
          p = ObjectSpace._id2ref(aroids[self.object_id])
          if p.is_a? Hash
            p.merge!({_obj_id: '&' << stamp}) unless p[:_obj_id]
          elsif p.is_a? String
            p << ' _&' << stamp unless p =~ / _&id/
          elsif p.is_a? Array
            p << ('_&' << stamp) unless p.include?('_&' << stamp)
          else
            # raise "Can't add id backreference to object: #{p.inspect}"
            nil
          end
          # return this backreference
          o = '*' << stamp
        else # we don't care where it's first referenced. just say it's a circular ref
          o = :_circ_obj_ref
        end
      end
      o
    else # we have exceeded the maximum representational depth
      if self.is_a? Hash
        {self.keys.first => :_max_depth_exc}
      elsif self.is_a? Array
        [:_max_depth_exc]
      else
        :_max_depth_exc
      end
    end
  end
end

########## inline test running
if __FILE__==$PROGRAM_NAME
  class ObjectUtilsTest < Test::Unit::TestCase
    def setup
      @timenow = Time.now
      @simple_nested_hash = {a: {b: 5, c: {d: 8, f: [1,2,[{g: 8},5]]}}}
      @complex_hash_object = {
        a: {
          b: [
               g=$stdout,
               TestClassWithAtts.new(att1: g, att2: TestProc.new{self}, dt: @timenow)
             ],
          c: {
            d: 5,
            e: {
              f: TestClassWithAtts,
              g: g
            }
          }
        }
      }
      @hash_previous = @complex_hash_object.hash
      # this had timed out in the past so wrapping it here in a timeout call
      @representation ||= begin
        timeout(1) do
          @complex_hash_object.represent
        end
      end
    end
    def test_circular_object_reference
      assert_equal :_circ_obj_ref, @representation[:a][:c][:e][:g]
    end

  def test_inspect_without_obj_id
    assert_nil TestClassWithAtts.inspect_without_obj_id =~ /\:0x[0-9a-f]+/
  end

  def test_maxdepth_exceeded
    assert_equal({:a=>{:b=>:_max_depth_exc, :c=>{:d=>:_max_depth_exc}}},
      @simple_nested_hash.represent(maxdepth: 3))
  end

  def test_represent_with_block_filter
    expected_result = {:a=>{:c=>{:e=>{:f=>"ObjectUtilsTest::TestClassWithAtts"}}}}
    filter = ->(k,v){ k.to_s.match(/a|c|e|f/) }
    assert_equal expected_result, @complex_hash_object.represent(prune: filter)
  end

  def test_represent_doesnt_mutate_original_object_whatsoever
    assert_equal @hash_previous, @complex_hash_object.hash
  end

  def test_represent_as_json
    assert_equal("object_utils_test/test_class_with_atts",
      @complex_hash_object[:a][:b][1].represent(as_json: true).keys.first)
  end

  def test_represent_with_backreferences
    expected_result = {
      :a=>
        {:b=>
          [{"IO"=>"#<IO:<STDOUT>>", :_obj_id=>"&id005"},
           {"ObjectUtilsTest::TestClassWithAtts"=>
             {"att1"=>"*id005",
              "att2"=>
               {"ObjectUtilsTest::TestProc"=>
                 @complex_hash_object[:a][:b][1].att2.inspect_without_obj_id},
              "dt"=>@timenow.utc.iso8601}}],
         :c=>{:d=>5, :e=>{:f=>"ObjectUtilsTest::TestClassWithAtts", :g=>"*id005"}}}}
    assert_equal(expected_result,
      @complex_hash_object.represent(include_backreferences: true))
  end

  def test_represent_on_ridiculous_object
    expected_result = {
      :a=>
        {:b=>
          [{"IO"=>"#<IO:<STDOUT>>"},
           {"ObjectUtilsTest::TestClassWithAtts"=>
             {"att1"=>:_circ_obj_ref,
              "att2"=>
               {"ObjectUtilsTest::TestProc"=>
                 @complex_hash_object[:a][:b][1].att2.inspect_without_obj_id},
              "dt"=>@timenow.utc.iso8601}}],
         :c=>{:d=>5, :e=>{:f=>"ObjectUtilsTest::TestClassWithAtts", :g=>:_circ_obj_ref}}}}

    assert_equal expected_result, @representation
  end

  def test_represent_with_empty_hash_values
    assert_equal({"--"=>{}, "++"=>{}}, {'val' => {}}.deep_diff({'val' => {}}))
  end