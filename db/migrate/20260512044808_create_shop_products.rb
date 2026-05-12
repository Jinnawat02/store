class CreateShopProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :shop_products do |t|
      t.references :shop, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true

      t.timestamps
    end
  end
end
