class AssignmentsController < ApplicationController
  before_action :set_assignment, only: %i[show edit update destroy]

  def index
    @assignments = Assignment.includes(:site, :employee).order(start_date: :desc)
  end

  def show; end

  def new
    @assignment = Assignment.new
    @sites = Site.order(:name)
    @employees = Employee.order(:name)
  end

  def edit
    @sites = Site.order(:name)
    @employees = Employee.order(:name)
  end

  def create
    @assignment = Assignment.new(assignment_params)
    if @assignment.save
      redirect_to @assignment, notice: "配置を登録しました"
    else
      @sites = Site.order(:name)
      @employees = Employee.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @assignment.update(assignment_params)
      redirect_to @assignment, notice: "配置情報を更新しました"
    else
      @sites = Site.order(:name)
      @employees = Employee.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @assignment.destroy
    redirect_to assignments_path, notice: "配置を削除しました"
  end

  private

  def set_assignment
    @assignment = Assignment.includes(:site, :employee).find(params[:id])
  end

  def assignment_params
    params.require(:assignment).permit(:site_id, :employee_id, :start_date, :end_date)
  end
end
