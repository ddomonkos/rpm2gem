require 'tmpdir'

module Rpm2Gem

  class InvalidPackageError < StandardError; end
  class RpmError < StandardError; end

  def self.unpack_rpm(rpms)
    rpms = [rpms] unless rpms.kind_of?(Array)

    unpack_dir = Dir.mktmpdir
    rpms.each do |r|
      cmd_out = `rpm2cpio #{r.file_path} | (cd #{unpack_dir} &&\
                 cpio -idm --quiet) 2>&1`
      raise("Failed to unpack an RPM, debug: #{cmd_out}") unless $?.success?
    end
    unpack_dir
  end
  
  def self.load_changelog(rpm)
    query = `rpm -qp --queryformat '[* %{CHANGELOGTIME} %{CHANGELOGNAME}\n%{CHANGELOGTEXT}\n]' #{rpm.file_path} 2>&1`
    raise InvalidPackageError unless $?.success?
    query
  end

  class Rpm
  
    attr_reader :file_path, :file_name, :name, :version, :release, :summary,
                :description, :license, :url, :os, :arch, :deps

    def initialize(file_path)
      @file_path = File.expand_path(file_path)
      @file_name = File.basename(file_path)
      @is_source = Rpm.source?(file_path)

      queryformat =
<<EOS
%{NAME}
%{VERSION}
%{RELEASE}
%{SUMMARY}
%{LICENSE}
%{URL}
%{ARCH}
%{DESCRIPTION}
EOS

      query = `rpm -qp --queryformat '#{queryformat}' #{file_path} 2>&1`
      raise(InvalidPackageError, query) unless $?.success?

      @name, @version, @release, @summary,\
      @license, @url, @arch, @description = query.split(/\n/, 8)
      @os = @release[/\.(.+)$/, 1]
      
      query = `rpm -qp --queryformat '[%{REQUIRENAME},%{REQUIREFLAGS:depflags}%{REQUIREVERSION}\n]' #{file_path} 2>&1`
      
      @deps = {}
      query.split(/\n/).each do |line|
        items = line.split(',')
        @deps[items[0]] = items[1]
      end
    end

    def source?
      @is_source
    end
    
    def noarch?
      @arch == 'noarch'
    end
    
    def self.name_version(file)
      query = `rpm -qp --queryformat '%{NAME},%{VERSION}' #{file} 2>&1`
      raise(RpmError, query) unless $?.success?
      query.split(',')
    end

    def self.source?(file)
      query = `rpm -qp --queryformat '%{SOURCEPACKAGE}' #{file} 2>&1`
      raise(RpmError, query) unless $?.success?
      query == '1'
    end
    
    def self.os(file)
      query = `rpm -qp --queryformat '%{RELEASE}' #{file} 2>&1`
      raise(RpmError, query) unless $?.success?
      query[/\.(.+)$/, 1]
    end
    
    def self.arch(file)
      query = `rpm -qp --queryformat '%{ARCH}' #{file} 2>&1`
      raise(RpmError, query) unless $?.success?
      query
    end
    
    def self.noarch?(file)
      query = `rpm -qp --queryformat '%{ARCH}' #{file} 2>&1`
      raise(RpmError, query) unless $?.success?
      query == 'noarch'
    end
    
  end
  
end
