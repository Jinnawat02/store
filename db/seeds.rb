# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create Categories
categories = [ "Electronics", "Books", "Clothing" ].map do |category_name|
  Category.find_or_create_by!(name: category_name)
end

# Create Products
products = []
10.times do |i|
  product = Product.find_or_create_by!(
    name: "Product #{i + 1}",
    category: i < 9 ? categories.sample : nil # 9 products have categories, 1 does not
  )
  products << product
end

# Create Shops
4.times do |i|
  shop = Shop.find_or_create_by!(
    name: "Shop #{i + 1}",
  )

  # Assign at least 3 products to each shop
  shop_products = products.sample(3)
  shop_products.each do |product|
    ShopProduct.find_or_create_by!(shop: shop, product: product)
  end
end
