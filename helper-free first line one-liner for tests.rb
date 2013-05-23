$LOAD_PATH.tap{|lp| lp.push(*%w[ test lib . ].map{|d| File.join(Dir.pwd.split(File::SEPARATOR).take_while{|p| p != 'test'}, d)})}.uniq!


# or

proj_root = (defined?(Rails) && Rails.respond_to?(:root) && Rails.root) || File.dirname(__FILE__).split(File::SEPARATOR).take_while{|p| p != 'test'}
add_paths = %w[ test lib app ].map{|d| File.join proj_root, d}
$LOAD_PATH.push(*add_paths)
at_exit { $LOAD_PATH.reverse!; add_paths.each{|p| $LOAD_PATH.delete p }; $LOAD_PATH.reverse! }

# or

def with_temp_load_path(*args)
  args = args.flatten
  determine_root = ->{ (defined?(Rails) && Rails.root.split(File::SEPARATOR)) || File.dirname(__FILE__).split(File::SEPARATOR).take_while{|p| p != 'test'} }
  if args.first.is_a?(Array)
    dirs = args.dup
    root = determine_root.call
  elsif args.first.is_a?(Hash)
    dirs = args.first[:dirs] || []
    root = args.first[:root] || determine_root.call
  end
  paths = [root] | dirs.map{|d| File.join(root, d)}
  $LOAD_PATH.unshift(*paths)
  yield
  paths.each{|p| $LOAD_PATH.delete p }
end
