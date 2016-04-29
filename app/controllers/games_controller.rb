class GamesController < ApplicationController
  def index
      @games = Game.all
  end
  
  def new
  end
  
  def create
    if current_user
      logger.debug current_user.inspect
      @game = Game.new()
      @game.add_user(User.find(current_user.id))
     
      @game.save
      redirect_to @game
    end
  end
  
  def show
      @game = Game.find(params[:id])
  end

  def game
  end
  
  def update
    @game=Game.find(params[:id])
    @game.add_user(User.find(current_user.id))
    @game.save
    redirect_to @game
  end
end