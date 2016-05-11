require "hash_helper"

module Projects

  class ExportRawTransformer

    include HashHelper

    def transform(original_hash)
      insert_into_hash_after(original_hash, :price_group, project: :project)
    end

  end

end
