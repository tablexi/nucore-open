survey "Test Survey" do

  section "Test Section" do

    label "Test Label"
    group "Test Group" do
      q "DNA Type", :pick => :one
      a "dsDNA"
      a "ssDNA"
      a "PCR"
      
      q "Purification Method", :pick => :one
      a "none"
      a "CsCl"
      a "QIAGEN Column"
      a "ABI Column"
      a "Promega Wizard"
      a "Phenol"
      a "Alkali lysis"
      a "other miniprep"
      a "other method"
    end

    label "Test Label 2"
    q "DNA Type", :pick => :one
    a "dsDNA"
    a "ssDNA"
    a "PCR"
    
    q "Purification Method", :pick => :one
    a "none"
    a "CsCl"
    a "QIAGEN Column"
    a "ABI Column"
    a "Promega Wizard"
    a "Phenol"
    a "Alkali lysis"
    a "other miniprep"
    a "other method"
  end

end

