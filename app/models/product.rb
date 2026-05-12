class Product < ApplicationRecord
  validates :name, presence: true

  belongs_to :category, optional: true
  has_many :shop_products, dependent: :destroy
  has_many :shops, through: :shop_products
end
