exceptions, tree, indent = [], {}, 0

# require 'active_support/all'

ObjectSpace.each_object(Class) do |cls|
  next unless cls.ancestors.include? Exception
  next if exceptions.include? cls
  next if cls.superclass == SystemCallError # avoid dumping Errno's
  exceptions << cls
  cls.ancestors.delete_if {|e| [Object, Kernel].include? e }.reverse.inject(tree) {|memo,cls| memo[cls] ||= {}}
end

tree_printer = Proc.new do |t, indent=0|
  t.keys.sort { |c1,c2| c1.name <=> c2.name }.each do |k|
    space = (' ' * indent); space ||= ''
    puts space + k.to_s
    tree_printer.call(t[k],indent+2)
  end
end

tree_printer.call tree
