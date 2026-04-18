class CategoriesController < ApplicationController
  def index
    @categories = current_user.categories.order(:name)
  end

  def options
    @categories = current_user.categories.order(:name).select(:id, :name, :color, :icon)
    render json: @categories.map { |c| { id: c.id, name: c.name, color: c.color, icon: c.icon } }
  end

  def create
    @category = current_user.categories.build(category_params)

    if @category.save
      redirect_to categories_path, notice: "Category created"
    else
      @categories = current_user.categories.order(:name)
      render :index, status: :unprocessable_entity
    end
  end

  def show
    @category = current_user.categories.find(params[:id])
  end

  def edit
    @category = current_user.categories.find(params[:id])
  end

  def update
    @category = current_user.categories.find(params[:id])

    if @category.update(category_params)
      redirect_to categories_path, notice: "Category updated"
    else
      @categories = current_user.categories.order(:name)
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    @category = current_user.categories.find(params[:id])
    @category.destroy
    redirect_to categories_path, notice: "Category deleted"
  end

  def reset
    current_user.categories.reset_to_defaults!
    redirect_to categories_path, notice: "Categories reset to defaults"
  end

  private

  def category_params
    params.require(:category).permit(:name, :color, :icon, :category_group)
  end
end
