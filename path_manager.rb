
module Desk
  module FileExtensions
    def add_to_front_of_load_path_relative_to(that_file, *paths)
      if paths.empty?
        the_path = File.expand_path(File.dirname(path))
        $LOAD_PATH.unshift(the_path) unless $LOAD_PATH.include?(the_path)
      end
      paths.each do |path|
        the_path = File.expand_path(File.join(File.dirname(that_file), path))
        $LOAD_PATH.unshift(the_path) unless $LOAD_PATH.include?(the_path)
      end
    end
    alias add_to_load_path_relative_to, add_to_front_of_load_path_relative_to
  end
end

class File
  extend Desk::FileExtensions
end
