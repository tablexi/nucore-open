# frozen_string_literal: true

module FaviconsHelper

  def load_favicons
    images = []
    Dir.glob("app/assets/images/favicons/*.png").each  do |png|
      rel = (png.include? "apple-touch-icon") ? "apple-touch-icon" : "shortcut icon"
      images.push({path: 'favicons/' + File.basename(png), rel: rel, type: "image/png"})
    end
    Dir.glob("app/assets/images/favicons/*.svg").each  do |svg|
      images.push({path: 'favicons/' + File.basename(svg), rel: 'shortcut icon', type: "image/svg"})
    end
    return images
  end

end
