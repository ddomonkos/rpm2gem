module Rpm2Gem
  private
  
  # Convert a path, so that it is relative to the specified directory.
  #
  def self.path_relative_to(path, dir)
    dir1 = File.expand_path(dir)
    path1 = File.expand_path(path)
    return path1.gsub(/\A#{dir1}\/*/, '')
  end
  
end
