survey "Alpha service survey" do
  
  section "Questions" do
    label "Colors say a lot about you, so tell the truth."
    # help_text "Colors say a lot about people"
    
    # multiple choice, 1 answer
    question_1 "What is your favorite color?", :pick => :one
    # help_text "Colors say a lot about people"
    answer "red"
    answer "blue"
    answer "green"
    answer "yellow"
    answer :other

    label "Tell us what you like so we order the right stuff."

    # multiple choice, multiple answers
    q_2 "Choose your favorite pizza toppings", :pick => :any
    a_1 "cheese"
    a_2 "pepporoni"
    a_3 "green peppers"
    a_4 "mushrooms"
    validation :rule => "A"
    # condition_A "=~", :regexp => /cheese|pepporoni|green peppers|mushrooms/
    condition_A "=~", :regexp => /cheese/
  end # section

end