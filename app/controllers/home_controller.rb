class HomeController < ApplicationController
  def index
    @recent_products = Product.order(created_at: :desc)
    @recent_categories = Category.order(created_at: :desc)
    @recent_shops = Shop.order(created_at: :desc)

    @products_count = @recent_products.count
    @categories_count = @recent_categories.count
    @shops_count = @recent_shops.count
  end
end
