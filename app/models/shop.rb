class Shop < ApplicationRecord
  has_many :shop_products
  has_many :products, through: :shop_products
end
