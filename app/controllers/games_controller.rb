class GamesController < ApplicationController
  before_filter :set_game_context, except: [:create, :index]

  def index
    @games = Game.all
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
    @game_push_channel_name = "game_" + @game.id.to_s + "_notifications_channel"
    @game_chat_channel_name = "game_" + @game.id.to_s + "_chat"
  end

  def play_turn
    game_channel = "game_" + @game.id.to_s + "_notifications_channel"
    Pusher.trigger(game_channel, 'next_turn', {
      user_id: params[:user_id],
      username: params[:username]
    });
    render json: {}, status: :ok
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

  def join
    if @game.active?
      flash[:alert] = 'That game has already started.'
      index and return
    else
      @game.add_user(current_user)
      flash[:notice] = "You have joined game ##{@game.id}!"
      redirect_to @game and return
      # TODO: Use socket to alert everyone that someone has joined the game
    end
  end

  private

  def set_game_context
    raise ActionController::RoutingError.new('Bad Request') unless current_user.present?

    @game = Game.find_by_id(params[:id] || params[:game_id])
    raise ActionController::RoutingError.new('Not Found') unless @game
  end
end
