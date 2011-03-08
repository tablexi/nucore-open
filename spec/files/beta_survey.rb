survey "Beta service survey" do

  section "Questions" do
    label "Drinking is considered a sport in many countries."
    # multiple choice, 1 answer
    question_1 "What is your favorite drink?", :pick => :one
    answer "Dirty Martini"
    answer "Scotch - neat"
    answer "Scotch - rocks"
    answer "Beer"
    answer :other
  end

end