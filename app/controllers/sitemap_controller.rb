class SitemapController < ApplicationController
  def sitemap
    @items = Item.where("is_public = TRUE")
    @collections = Collection.where("items_visible_by_default = TRUE")
  end
end