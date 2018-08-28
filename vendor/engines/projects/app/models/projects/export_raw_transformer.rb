# frozen_string_literal: true

require "hash_helper"

module Projects

  class ExportRawTransformer

    include HashHelper

    def transform(original_hash)
      insert_into_hash_after(original_hash, :charge_for, project: :project)
    end

  end

end
