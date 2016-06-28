class SangerSequencing.WellPlateColors

  constructor: (@builder) -> undefined

  colors = ["#1F77B4", # blue
            "#98DF8A", # green
            "#9467BD", # purple
            "#FFBB78", # light orange
            "#AEC7E8", # light blue
            "#C7C7C7", # grey
            "#D62728", # red
            "#C49C94", # light brown
            "#FF7F0E", # orange
            "#BCBD22", # pea green
            "#8C564B", # brown
            "#FF9896", # rose
            "#E377C2", # pink/purple
            "#17BECF", # teal
            "#2CA02C", # green
            "#C5B0D5", # light purple
            "#7F7F7F", # dark grey
            "#9EDAE5" # light teal
          ]


  styleForSubmissionId: (submissionId) ->
    index = (@submissionIndex(submissionId) % colors.length)
    { "background-color": colors[index] } if index >= 0

  submissionIndex: (submissionId) ->
    @builder.allSubmissions.map((submission) ->
      submission.id
    ).indexOf(submissionId)
