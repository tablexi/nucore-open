module Projects

  module OrderRowImporterExtension

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods

      def custom_headers
        [:project_id]
      end

    end

    private

    def custom_attributes
      { project_id: field(:project_id) }
    end

  end

end
