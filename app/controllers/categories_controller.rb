class CategoriesController < ApplicationController
  before_action :set_category, only: [ :show, :edit, :update, :destroy ]
  before_action :set_available_products, only: [ :new, :edit ]

  def index
    @categories = Category.order(:id)
  end

  def show
    @products = @category.products.order(:id)
  end

  def new
    @category = Category.new
  end

  def create
    @category = Category.new(category_params)
    if @category.save
      redirect_to @category
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @category.update(category_params)
      redirect_to @category
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @category.destroy
    redirect_to categories_path
  end

  private

  def set_category
    @category = Category.find(params[:id])
  end

  def category_params
    params.require(:category).permit(:name, product_ids: [])
  end

  def set_available_products
    @all_products = Product.where(category_id: nil).or(Product.where(category: @category)).order(:name)
  end
end
