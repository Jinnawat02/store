class ShopsController < ApplicationController
  before_action :set_shop, only: [ :show, :edit, :update, :destroy ]

  def index
    @shops = Shop.order(:id)
  end

  def show
    @products = @shop.products.order(:id)
  end

  def new
    @shop = Shop.new
    @all_products = Product.order(:name)
  end

  def create
    @shop = Shop.new(shop_params)
    if @shop.save
      redirect_to @shop
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @all_products = Product.order(:name)
  end

  def update
    if @shop.update(shop_params)
      redirect_to @shop
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @shop.destroy
    redirect_to shops_path
  end

  private

  def set_shop
    @shop = Shop.find(params[:id])
  end

  def shop_params
    params.require(:shop).permit(:name, product_ids: [])
  end
end
