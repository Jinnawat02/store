class Product < ApplicationRecord
  validates :name, presence: true

  belongs_to :category
  has_many :shop_products
  has_many :shop, through: :shop_products
end
