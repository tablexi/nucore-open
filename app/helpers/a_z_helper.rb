module AZHelper

  # Generates empty hash with keys for each letter
  ALPHABET = ('A'..'Z').to_a.map { |x| [x, []] }.to_h
  def get_AZList(facilities)
    ALPHABET.merge(facilities.group_by { |row| row.name[0] })
  end

  def get_Classname_For_Facility(index, letter)
    'azlist' + index.to_s
  end

end
