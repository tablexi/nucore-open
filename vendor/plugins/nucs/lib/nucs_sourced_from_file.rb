#
# Provides an interface for handling Northwestern University chart string (nucs) imports.
#
# Classes that include this module don't have to worry about
# reading their source file, reporting results, or handling
# errors. They just need to worry about parsing an input line
# and creating a model out of the input.
module NucsSourcedFromFile
  include NucsErrors

  #
  # source line data delimiter
  NUCS_TOKEN_SEPARATOR='|'


  def self.included(base)
    base.extend(ClassMethods)
  end


  module ClassMethods
    #
    # Creates and saves an +ActiveRecord+ model
    #
    # [_tokens_]
    #   the result of +#tokenize_source_line+
    # [_returns_]
    #   the created model whether or not the save was a success.
    # [_note_]
    #   Implementers should not let a +ActiveRecord::RecordInvalid+
    #   error raise if calling +ActiveRecord::Base#save!+.
    def create_from_source(tokens)
      raise 'Must be implemented!'
    end


    #
    # Parses a data input line
    #
    # [_source_line_]
    #   A +NUCS_TOKEN_SEPARATOR+ delimited input line
    # [_returns_]
    #   An +Array+ of the data parsed from +source_line+
    def tokenize_source_line(source_line)
      return source_line.split(NUCS_TOKEN_SEPARATOR)
    end


    #
    # Reads an input file line by line ingesting each and
    # saving it to the DB if the data is valid
    #
    # [_source_file_]
    #   Full path to +NUCS_TOKEN_SEPARATOR+ delimited file
    # [_raises_]
    #   Any error that doesn't have to do with invalid data
    # [_outputs_]
    #   Warnings about invalid data and a 1-line summary of
    #   the overall import
    def source(source_file)
      imported, invalid=0, 0

      transaction do
        delete_all

        File.readlines(source_file).each_with_index do |line, ndx|
          line.strip!

          begin
            record=create_from_source(tokenize_source_line(line))
            raise NucsErrors::ImportError.new(record.errors.full_messages.join(', ')) unless record.valid?
            imported += 1
          rescue NucsErrors::ImportError => e
            puts "invalid data on line ##{ndx+1} of #{File.basename(source_file)} (#{line}) :: #{e.message}"
            invalid += 1
          end
        end

        puts "imported #{imported} records, found #{invalid} invalid records"
      end
    end

  end
end