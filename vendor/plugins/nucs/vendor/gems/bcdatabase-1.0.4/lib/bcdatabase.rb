require 'yaml'
require 'openssl'
require 'digest/sha2'
require 'base64'

module Bcdatabase
  autoload :VERSION,  'bcdatabase/version'
  autoload :Commands, 'bcdatabase/commands'

  DEFAULT_BASE_PATH = File.join('/', 'etc', 'nubic', 'db')
  DEFAULT_PASS_FILE = File.join('/', 'var', 'lib', 'nubic', 'db.pass')
  CIPHER = 'aes-256-ecb'

  class << self
    def load(path=nil)
      path ||= base_path
      files = Dir.glob(File.join(path, "*.yml")) + Dir.glob(File.join(path, "*.yaml"))
      DatabaseConfigurations.new(files)
    end

    def encrypt(s)
      Base64.encode64(encipher(:encrypt, s)).strip
    end

    def decrypt(s)
      encipher(:decrypt, Base64.decode64(s))
    end

    def pass_file
      ENV["BCDATABASE_PASS"] || DEFAULT_PASS_FILE
    end

    private

    # based on http://snippets.dzone.com/posts/show/576
    def encipher(direction, s)
      # the order of operations here is very important
      c = OpenSSL::Cipher::Cipher.new(CIPHER)
      c.send direction
      c.key = pass
      t = c.update(s)
      t << c.final
    end

    def pass
      return @pass if instance_variable_defined? :@pass

      contents = open(pass_file).read.chomp
      # This code may not work correctly on Ruby 1.9
      if contents.size == 32
        @pass = contents
      else
        @pass = Digest::SHA256.digest(contents)
      end
    end

    def base_path
      ENV["BCDATABASE_PATH"] || DEFAULT_BASE_PATH
    end
  end

  class DatabaseConfigurations
    def initialize(files)
      @files = files
      @map = { }
      files.each do |filename|
        name = File.basename(filename).gsub(/\.ya?ml/, '')
        @map[name] = YAML.load(File.open(filename))
      end
    end

    def [](groupname, dbname)
      create_entry(groupname.to_s, dbname.to_s)
    end

    def method_missing(name, *args)
      groupname = (args[0] or raise "Database configuration group not specified for #{name}")
      dbname = (args[1] or raise "Database entry name not specified for #{name}")
      n = name.to_s
      begin
        unseparated_yaml(n => self[groupname, dbname])
      rescue Bcdatabase::Error => e
        if defined?(RAILS_ENV) and RAILS_ENV == n
          raise e
        else
          # Not using that configuration right now, so return a dummy instead
          # of throwing an exception
          unseparated_yaml(n => { 'error' => e.message })
        end
      end
    end

    private

    def create_entry(groupname, dbname)
      group = @map[groupname] or raise Error.new("No database configuration group named #{groupname.inspect} found.  (Found #{@map.keys.inspect}.)")
      db = group[dbname] or raise Error.new("No database entry for #{dbname.inspect} in #{groupname}")
      merged = { 'username' => dbname, 'database' => dbname } \
        .merge(group['defaults'] || {}) \
        .merge(group['default'] || {}) \
        .merge(db)
      # include the decrypted password if an encrypted one was provided
      if merged['epassword']
        merged['password'] = Bcdatabase.decrypt(merged['epassword'])
      end
      merged
    end

    def unseparated_yaml(arg)
      arg.to_yaml.gsub(/^---.*\n/, '')
    end
  end

  class Error < Exception; end
end
