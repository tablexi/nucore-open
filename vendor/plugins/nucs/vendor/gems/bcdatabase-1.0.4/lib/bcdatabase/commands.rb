require 'rubygems'
require 'fileutils'
require 'highline'
require 'active_support'
require 'active_support/core_ext/string/inflections'
require 'bcdatabase'

HL = HighLine.new

module Bcdatabase::Commands
  class Base
    protected

    def self.usage(use)
      "usage: #{UTILITY_NAME} #{use}"
    end

    def self.help_message(use)
      msg = [ "#{command_name}: #{summary}", usage(use), "" ]
      yield msg if block_given?
      msg.join("\n")
    end
  end

  class Epass < Base
    def initialize(argv)
      @streaming = argv[-1] == '-'
    end

    def self.summary
      "Generate epasswords from individual database passwords"
    end

    def self.help
      help_message("epass [-]") do |msg|
        msg << "With no arguments, interactively prompts for passwords and"
        msg << "  prints the corresponding epassword entry."
        msg << ""
        msg << "If the last argument is -, reads a newline-separated list"
        msg << "  of passwords from standard in and prints the corresponding "
        msg << "  epasswords to standard out."
      end
    end

    def main
      @streaming ? streamed : interactive
    end

    private

    def streamed
      $stdin.readlines.each do |line|
        puts Bcdatabase.encrypt(line.chomp)
      end
      0
    end

    def interactive
      begin
        loop do
          pass = HL.ask("Password (^C to end): ") do |q|
            q.echo = false
          end
          puts "  epassword: #{Bcdatabase.encrypt(pass)}"
        end
      rescue Interrupt
        puts "\nQuit"
      end
      0
    end
  end

  class Encrypt < Base
    def initialize(argv)
      @input = argv.shift
      @output = argv.shift
    end

    def self.summary
      "Encrypts all the password entries in a bcdatabase YAML file"
    end

    def self.help
      help_message("encrypt [inputfile [outputfile]]") do |msg|
        msg << "Specifically, this command finds all the keys named 'password'"
        msg << "  in the input YAML and substitutes appropriate 'epassword'"
        msg << "  keys."
        msg << ""
        msg << "If inputfile is specified, the source will be that file."
        msg << "  If not, the source will be standard in."
        msg << ""
        msg << "If inputfile and outputfile are specified, the new file"
        msg << "  will be written to the output file.  Otherwise the output"
        msg << "  will go to standard out.  Input and output may be the same"
        msg << "  file."
        msg << ""
        msg << "You can't read from standard in and write to a file directly; "
        msg << "  use shell file redirection if you need to do that."
      end
    end

    def main
      inio =
        if @input
          open(@input, "r")
        else
          $stdin
        end
      # try to preserve the order by replacing everything using regexes
      contents = inio.read
      contents.gsub!(/\bpassword:(\s*)(\S+)\s*?$/) { "epassword:#{$1}#{Bcdatabase.encrypt($2)}" }
      outio =
        if @output
          open(@output, "w")
        else
          $stdout
        end
      outio.write(contents)
      outio.close
      0
    end
  end

  class Help < Base
    def initialize(argv)
      @cmd = argv.shift
    end

    def self.summary
      "List commands or display help for one; e.g. #{UTILITY_NAME} help epass"
    end

    def self.help
      help_message "help [command name]"
    end

    def main
      if @cmd
        klass = Bcdatabase::Commands[@cmd]
        if klass
          msg = klass.respond_to?(:help) ? klass.help : klass.summary
          $stderr.puts msg
        else
          $stderr.puts "Unknown command #{@cmd}"
          return 1
        end
      else
        $stderr.puts Bcdatabase::Commands.help
      end
      0
    end
  end

  class GenKey < Base
    def initialize(argv)
      @stream = argv[-1] == '-'
    end

    def self.summary
      "Generate a key for bcdatabase to use"
    end

    def self.help
      help_message("gen-key [-]") do |msg|
        msg << "By default, the key will be generated in "
        msg << "  #{Bcdatabase.pass_file}.  If the last argument to this"
        msg << "  command is -, the key will be generated to standard out"
        msg << "  instead."
        msg << ""
        msg << "CAUTION: writing to #{Bcdatabase.pass_file} may overwrite"
        msg << "  an existing bcdatabase key.  If that happens, you will"
        msg << "  need to reencrypt all the epasswords on this machine."
      end
    end

    def main
      key = random_key(128)
      outio =
        if @stream
          $stdout
        else
          file = Bcdatabase.pass_file
          if File.exist?(file)
            sure = HL.ask("This operation will overwrite the existing pass file.\n  Are you sure you want to do that? ", %w{yes no}) do |q|
              q.case = :down
            end
            unless sure == 'yes'
              exit(0)
            end
          end
          open(file, "w")
        end
      outio.write key
      outio.close
      0
    end

    private

    def random_key(length)
      k = ""
      # This is probably not going to work in ruby 1.9
      until k.size == length; k << rand(126 - 32) + 32; end
      k
    end
  end

  class << self
    def help
      all_help = commands.collect { |c| [c.command_name, c.summary] }.sort_by { |p| p[0] }
      max_name_length = all_help.collect { |a| a[0].size }.max
      msg = Base.usage "<command> [args]\n"
      msg << "Utility for bcdatabase #{Bcdatabase::VERSION}\n"
      msg << "Commands:\n"
      msg << all_help.collect { |name, help| " %#{max_name_length + 1}s  %s" % [name, help] }.join("\n")
    end

    # Lists all the commands
    def commands
      constants.reject { |cs| cs == "Base" }.collect { |cs| const_get(cs) }.select { |c| c.kind_of? Class }
    end

    # Locates the command class for a user-entered command name.
    # Returns nil if the name is invalid.
    def command(command_name)
      begin
        klassname = command_name.gsub('-', '_').camelize
        Bcdatabase::Commands.const_get "#{klassname}"
      rescue NameError
        nil
      end
    end
    alias :[] :command
  end
end

class Class
  def command_name
    name.gsub(Bcdatabase::Commands.name + "::", '').underscore.gsub("_", '-')
  end
end
