class NucsProjectActivity < NucsGe001
  validates_format_of(:project, :with => /^\d{8,15}$/)
  validates_format_of(:activity, :with => /^\d{2,15}$/)


  def self.create_from_source(tokens)
    attrs={ :project => tokens[0], :activity => tokens[1] }
    attrs.merge!(:auxiliary => tokens[2]) if tokens.size > 2
    create(attrs)
  end


  def self.tokenize_source_line(source_line)
    ndx=source_line.index(NUCS_TOKEN_SEPARATOR)
    raise ImportError.new unless ndx

    tokens=[ source_line[0...ndx] ]
    raise ImportError.new unless source_line.size > ndx+1

    nxt_ndx=source_line.index(NUCS_TOKEN_SEPARATOR, ndx+1)
    raise ImportError.new unless nxt_ndx

    tokens << source_line[ndx+1...nxt_ndx]
    tokens << source_line[nxt_ndx+1..-1] if source_line.size > nxt_ndx+1
    return tokens
  end

end