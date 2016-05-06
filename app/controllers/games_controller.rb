class GamesController < ApplicationController
  before_filter :set_game_context, except: [:create, :index]
  before_filter :set_pusher_context, except: [:create, :index]

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
    if @game.valid_player_count? && !@game.active?
      @game.start_game!
      data = @game.as_json
    else
      data = { error: 'Not enough players or game has already started.' }
    end

    @pusher_client.trigger(@pusher_channel, 'game.start', data)
    render json: {}
  end

  def join
    if @game.active?
      flash[:alert] = 'That game has already started.'
      index and return
    else
      @game.add_user(current_user)
      flash[:notice] = "You have joined game ##{@game.id}!"
      @pusher_client.trigger(
        @pusher_channel,
        'user.joined',
        username: current_user.username
      )

      redirect_to @game and return
    end
  end

  private

  def set_game_context
    raise ActionController::RoutingError.new('Bad Request') unless current_user.present?

    @game = Game.find_by_id(params[:id] || params[:game_id])
    raise ActionController::RoutingError.new('Not Found') unless @game
  end

  def set_pusher_context
    @pusher_client = Pusher.default_client
    @pusher_channel = "game_#{@game.id}_notifications_channel"
  end
end
