class GamesController < ApplicationController
  before_filter :set_game_context, except: [:create, :index]
  before_filter :set_pusher_context, except: [:create, :index]

  def index
    @games = Game.all
    return
  end

  def create
    if current_user
      @game = Game.new
      @game.add_user(current_user)

      @game.save!

      set_pusher_context
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

      # send basic info about all players in game, (ids, usernames)
      @pusher_client.trigger(@main_channel, 'game.start', @game.as_json)

      # tell each player what hand they have...1 card at a time
      # Pusher limits the size of data sent at one time to 10kB
      @game.players.each do |player|
        player.hand.each do |card|
          @pusher_client.trigger(
            @game.channel_for_player(player),
            'player.hand.updated',
            { card: card.as_json, action: 'add' }
          )
        end
      end

      # tell whoever is going first that it's their turn
      @pusher_client.trigger(
        @game.channel_for_player(@game.current_turn_player),
        'player.turn.start',
        {}
      )
    else
      @pusher_client.trigger(
        @main_channel,
        'game.start',
        { error: 'Not enough players or game has already started.' }
      )
    end

    render json: {}
  end

  def join
    if @game.active?
      flash[:alert] = 'That game has already started.'
      redirect_to games_path and return
    else
      @game.add_user(current_user)
      flash[:notice] = "You have joined game ##{@game.id}!"
      @pusher_client.trigger(
        @main_channel,
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
    @main_channel = "game_#{@game.id}_notifications_channel"
    @user_channel = @game.channel_for_player(current_user) if current_user
  end
end
