class SangerSequencing.WellPlateColors

  constructor: (@builder) -> undefined

  colorForSubmissionId: (submissionId) ->
    # 18 is a magic number coming from the number of colors we have defined in
    # our CSS classes
    index = (@submissionIndex(submissionId) % 18) + 1
    "sangerSequencing--colorCoded__color#{index}"

  submissionIndex: (submissionId) ->
    @builder.allSubmissions.map((submission) ->
      submission.id
    ).indexOf(submissionId)
