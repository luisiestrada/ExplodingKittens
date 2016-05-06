class GamesController < ApplicationController
  before_filter :set_game_context, except: [:new, :create, :index]

  def index
    @games = Game.all
  end

  def new
  end

  def create
    if current_user
      @game = Game.new
      @game.add_user(current_user)

      @game.save!

      flash[:notice] = 'New game!'
      redirect_to @game and return
    else
      flash[:alert] = 'You must be logged in to create a game.'
      redirect_to root_path and return
    end
  end

  def show
  end

  def start
    respond_to do |format|
      format.json do
        if @game.valid_player_count?
          @game.start_game!
          render json: @game.as_json
        else
          render json: { error: 'You need at least 2 players to start the game.' }
        end
      end
    end
  end

  def update
    @game.add_user(current_user)
    @game.save!
    redirect_to @game
  end

  private

  def set_game_context
    @game = Game.find_by_id(params[:id])
    not_found unless @game
  end
end
