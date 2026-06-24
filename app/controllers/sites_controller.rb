class SitesController < ApplicationController
  before_action :set_site, only: %i[show edit update destroy]

  def index
    @sites = Site.order(start_date: :desc)
  end

  def show
    @assignments = @site.assignments.includes(:employee).order(start_date: :asc)
  end

  def new
    @site = Site.new
  end

  def edit; end

  def create
    @site = Site.new(site_params)
    if @site.save
      redirect_to @site, notice: "現場を登録しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @site.update(site_params)
      redirect_to @site, notice: "現場情報を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @site.destroy
    redirect_to sites_path, notice: "現場を削除しました"
  end

  private

  def set_site
    @site = Site.find(params[:id])
  end

  def site_params
    params.require(:site).permit(:name, :address, :start_date, :end_date)
  end
end
