class HomeController < ApplicationController
  def index
    @products_count = Product.count
    @categories_count = Category.count
    @shops_count = Shop.count

    @recent_products = Product.order(created_at: :desc).limit(5)
    @recent_categories = Category.order(created_at: :desc).limit(5)
    @recent_shops = Shop.order(created_at: :desc).limit(5)
  end
end
