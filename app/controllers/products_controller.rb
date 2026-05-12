class ProductsController < ApplicationController
  before_action :set_product, only: [ :show, :edit, :update, :destroy ]

  def index
    @products = Product.order(:id)
  end

  def show
  end

  def new
    @product = Product.new
  end

  def create
    @product = Product.new(product_param)
    if @product.save
      redirect_to @product
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @product.update(product_param)
      redirect_to @product
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @product.destroy
    redirect_to products_path
  end

  private
  def set_product
    @product = Product.find(params[:id])
  end

  def product_param
    params.expect(product: [ :name ])
  end
end
