module AZHelper
    ALPHABET = ('A'..'Z').to_a

    def getAZList (facilities)
        azlist = Array.new(26)
        ALPHABET.each do |letter|
            setFacilitiesForLetter(letter, facilities, azlist)
        end
        return azlist
    end

    def  setFacilitiesForLetter(letter, facilities, azlist)
        index = ALPHABET.index(letter)
        azlist[index]= A_Z_Listing.new(letter, [])
        facilities.each do |facility|
            upperName = facility.name.upcase
            if upperName.start_with?(letter)
                azlist[index].pushFacility(facility)
            end
        end
    end
end
class A_Z_Listing
    def initialize(letter, facilities)
        @letter = letter
        @facilities = facilities
    end

    def pushFacility(facility)
        @facilities.push(facility)
    end

    def getLetter
        return @letter
    end

    def getFacilities
        return @facilities
    end
end