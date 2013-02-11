require 'rpm2gem/rpm'
require 'rpm2gem/helpers'
require 'fileutils'
require 'tmpdir'

module Rpm2Gem
  GEMS_DIR = 'gems'
  LIB_DIR = 'lib'
  EXT_DIR = 'ext'
  
  # Extract files with a .gem suffix from specified source RPM. Directories
  # containing the results must be removed afterwards.
  #
  def self.extract_gems_from_srpm(srpm)
    dir = Rpm2Gem.unpack_rpm(srpm)
    return Dir.glob("#{dir}/*.gem").select { |f| File.file?(f) }
  end
  
  # Unpack a Gem package. Returns the resulting directory (path).
  #
  def self.unpack_gem(gem_file)
    result_dir = nil
    Dir.mktmpdir do |unpack_dir|
      cmd_out = `gem unpack --target=#{unpack_dir} #{gem_file} 2>&1`
      raise("Failed to unpack a gem, debug: #{cmd_out}") unless $?.success?
      result_dir = Dir.mktmpdir
      FileUtils.mv(Dir.glob("#{unpack_dir}/*/*"), result_dir)
    end
    return result_dir
  end
  
  # Remove existing SO (Shared Object) files in the lib directory of given Gem.
  # Returns an array of files, that have been deleted.
  #
  def self.remove_built_so(base_dir)
    files = Dir.glob("#{base_dir}/#{LIB_DIR}/**/*.so")
    res = files.map { |f| path_relative_to(f, base_dir) }
    FileUtils.rm(files)
    return res
  end
  
  # Import files located in the ext directory of given Gem package into given
  # build directory, if they do not exist. Returns an array of files, that were
  # imported.
  #
  def self.import_ext_sources(gem_file, build_dir)
    unpack_dir = Rpm2Gem.unpack_gem(gem_file)
    files = Dir.glob("#{unpack_dir}/#{EXT_DIR}/**/*")
    files.reject! do |uf|
      bf = File.join(build_dir, path_relative_to(uf, unpack_dir))
      exists = File.exists?(bf)
      unless exists
        dir = File.dirname(bf)
        FileUtils.mkdir_p(dir)
        FileUtils.mv(uf, dir)
      end
      exists
    end
    FileUtils.rm_rf(unpack_dir)
    return files.map { |f| path_relative_to(f, unpack_dir) }
  end
  
end
