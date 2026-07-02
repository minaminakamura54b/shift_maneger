class EmployeesController < ApplicationController
  before_action :set_employee,        only: %i[show edit update destroy]
  before_action :require_admin!,       only: %i[new create]
  before_action :require_own_or_admin!, only: %i[edit update destroy]

  def index
    @employees = Employee.order(:name)
  end

  def show
    @assignments = @employee.assignments.includes(:site).order(start_date: :asc)
  end

  def new
    @employee = Employee.new
  end

  def edit; end

  def create
    @employee = Employee.new(employee_params)
    if @employee.save
      redirect_to @employee, notice: "社員を登録しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @employee.update(employee_params)
      redirect_to @employee, notice: "社員情報を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @employee.destroy
    redirect_to employees_path, notice: "社員を削除しました"
  end

  private

  def set_employee
    @employee = Employee.find(params[:id])
  end

  def employee_params
    params.require(:employee).permit(:name, :email, :phone)
  end
end
