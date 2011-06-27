class NucsGe001 < ActiveRecord::Base
  include NucsSourcedFromFile

  self.abstract_class=true

  validates_length_of(:auxiliary, :maximum => 512, :allow_nil => true)


  def self.create_from_source(tokens)
    attrs={ :value => tokens[0] }
    attrs.merge!(:auxiliary => tokens[1]) if tokens.size > 1
    create(attrs)
  end


  def self.tokenize_source_line(source_line)
    ndx=source_line.index(NUCS_TOKEN_SEPARATOR)
    raise ImportError.new unless ndx
    tokens=[ source_line[0...ndx] ]
    return tokens unless source_line.size > ndx+1
    tokens << source_line[ndx+1..-1]
    return tokens
  end

end