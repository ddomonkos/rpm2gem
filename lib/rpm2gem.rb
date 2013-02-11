require 'rpm2gem/rpm'
require 'rpm2gem/extensions'
require 'rubygems/specification'
require 'fileutils'
require 'tmpdir'

module Rpm2Gem
  VERSION = '0.1.0'

  # Prepare a directory for the 'gem build' command. The associated gemspec
  # will still need to be updated/modified though. Returns the dir path and
  # the path to the gemspec.
  # Creates a new directory in the tmp folder, if no result_dir is specified.
  #
  def self.prepare_dir(brpms, result_dir = nil)
    unpack_dir = Rpm2Gem.unpack_rpm(brpms)
    gemspec_file =
      begin
        files = Dir.glob(File.join(unpack_dir,
                         '**/specifications/*.gemspec'))
        raise('No gemspec found!') if files.size < 1
        raise('More than one gemspec found!') if files.size > 1
        files.first
      end
      
    begin
      gemspec = Gem::Specification.load(gemspec_file)
    rescue => ex
      FileUtils.rm_rf(unpack_dir)
      raise ex
    end
    result_dir ||= Dir.mktmpdir
    FileUtils.mv(Dir.glob("#{gemspec.gem_dir}/*"), result_dir)
    gemspec_file1 = File.join(result_dir, gemspec.spec_name)
    FileUtils.mv(gemspec_file, gemspec_file1)
    FileUtils.rm_rf(unpack_dir)
    return result_dir, gemspec_file1
  end

  # Produce the final Gem package. Returns the result (file path).
  #
  def self.build(base_dir, gemspec_file)
    cmd_out = `cd #{base_dir} && gem build #{File.basename(gemspec_file)} 2>&1`
    raise(cmd_out) unless $?.success?
    gemspec = Gem::Specification.load(gemspec_file)
    return "#{base_dir}/#{gemspec.file_name}"
  end
  
  # Extract and merge dependencies from specified RPMs. Returns runtime
  # dependencies and build dependencies, seperately.
  #
  def self.get_deps(*rpms)
    deps = rpms.inject({}) { |res, rpm|
      if rpm.source? then res else res.merge(rpm.deps) end }
    bdeps = rpms.inject({}) { |res, rpm|
      if rpm.source? then res.merge(rpm.deps) else res end }
    bdeps.delete_if { |name, version| deps.has_key?(name) }
    return deps, bdeps
  end
  
  # Translate RPM dependencies to Gem dependencies. Only dependencies on other
  # RubyGems libraries can be translated, others are dropped (it also assumes
  # that the dependent libraries follow Red Hat naming conventions). Returns
  # runtime dependencies and development dependencies, separately.
  #
  def self.translate_deps(rpm_deps, rpm_bdeps)
    gem_rundeps = {}
    rpm_deps.each do |n, v|
      match = n.strip.match(/\Arubygem\(?(.*?)\)\z/)
      gem_rundeps[match[1]] = v if match
    end

    gem_devdeps = {}
    rpm_bdeps.each do |n, v|
      match = n.strip.match(/\Arubygem\(?(.*?)\)\z/)
      gem_devdeps[match[1]] = v if match
    end
    
    return gem_rundeps, gem_devdeps
  end
  
end
