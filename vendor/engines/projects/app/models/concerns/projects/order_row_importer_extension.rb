module Projects

  module OrderRowImporterExtension

    def custom_attributes
      { project_id: field(:project_id) }
    end

  end

end
