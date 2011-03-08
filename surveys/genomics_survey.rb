survey "Genomics survey" do

  section "DNA Preparation Information" do
    # label "Colors say a lot about you, so tell the truth."
    # help_text "Colors say a lot about people"
    
    # multiple choice, 1 answer
    question_1 "DNA Type", :pick => :one, :display_type => :dropdown
    # help_text "Colors say a lot about people"
    answer "dsDNA"
    answer "ssDNA"
    answer "PCR"

    # text question
    q "Concentration"
    a :string
    # validations can use regexp values
    validation :rule => "A"
    condition_A "=~", :regexp => /[0-9\.]/
    label "ng/ul"

    # text question
    q "Sample Volume"
    a :integer
    validation :rule => "A"
    condition_A ">=", :integer_value => 0
    label "ul"

    # multiple choice, 1 answer
    q "Purification Method", :pick => :one, :display_type => :dropdown
    a "none"
    a "CsCl"
    a "QIAGEN Column"
    a "ABI Column"
    a "Promega Wizard"
    a "Phenol"
    a "Alkali lysis"
    a "other miniprep"
    a "other method"
    
    # multiple choice, 1 answer
    q "Measurement Method", :pick => :one, :display_type => :dropdown
    a "A260"
    a "Gel"
    a "Fluorimetry"

    # multiple choice, 1 answer
    q "Buffer", :pick => :one, :display_type => :dropdown
    a "10 mM  Tris-HCL"
    a "Water"
    a "Other"
    label "Water is preferred"

    #
    # "Primer Information"
    #
    label "Primer Information"

    # multiple choice, 1 answer
    question_1 "Concentration", :pick => :one, :display_type => :dropdown
    answer "0.8"
    answer "1.0"
    label "pMoles/ul"

    # text question
    q "Volume"
    a :integer
    label 'ul'

    #
    # "Cell Line and Vector Information"
    #
    label "Cell Line and Vector Information"

    # multiple choice, 1 answer
    question_1 "E-Coli Strain", :pick => :one, :display_type => :dropdown
    answer "Other"
    answer "HB101"

    # text question
    q "Vector Name"
    label "Vector information is only necessary for dsDNA"

    # text question
    q "Size"
    label "bp"

    # multiple choice, 1 answer
    question_1 "Vector Type", :pick => :one, :display_type => :dropdown
    answer "Plasmid"
    answer "Cosmid"
    answer "Phage"
    answer "YAC"
    answer "Other"

    #
    # "Special Instructions for Changing Cycling Parameters"
    #
    label "Special Instructions for Changing Cycling Parameters"
    
    # multiple choice, 1 answer
    question_1 "Please choose special instructions here", :pick => :one, :display_type => :dropdown
    answer "None"
    answer "GC Rich"
    answer "GT Rich"
    answer "CT Rich"
    answer "Hairpin"
    answer "Repeats"

    #
    # "Enter Multiple Sample Information Below"
    #
    label "Enter Multiple Sample Information Below"

    repeater "Sample Information" do
      # text question
      q "Sample Name"
      a :string
      q "Primer Name"
      a :string
      label "bp"
      q "Comments and/or Description"
      a :string
    end
  end
end