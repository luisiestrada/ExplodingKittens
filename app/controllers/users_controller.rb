class UsersController < ApplicationController
  helper_method :sort_column, :sort_direction
  
  def index
    if (!params[:sort].nil? && params[:sort] == 'wins')
      @users = User.joins("LEFT JOIN games ON users.id = games.winner_id").group("users.id").order("count(users.id) " + sort_direction).paginate(:per_page => 5, :page => params[:page])
    else
      @users = User.joins(:stats).order(sort_column + " " + sort_direction).paginate(:per_page => 5, :page => params[:page])
    end
  end
  
  def sort_column
    if (!params[:sort].nil?)
      return (User.column_names.include?(params[:sort]) || UserStat.column_names.include?((params[:sort].sub("stats.","")))) ? params[:sort] : "id"
    else
      return "id"
    end
  end
  
  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
  end
end
