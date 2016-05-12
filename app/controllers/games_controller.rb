class GamesController < ApplicationController
  before_filter :set_game_context, except: [:create, :index]
  before_filter :set_pusher_context, except: [:create, :index]

  def index
    @games = Game.with_players
  end

  def create
    if current_user
      @game = Game.new
      if params[:game].present?
        room_name = params[:game][:room_name]
        @game.room_name = room_name if room_name.present?
      end

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
    # get image tags for all the card assets
    i_tag = -> (str) { ActionController::Base.helpers.image_tag(str) }

    @attack_cards =
      ['attack-1','attack-2','attack-3','attack-4'].map { |c| i_tag.call(c) }

    @beard_cat = [i_tag.call('cat-3')]
    @hairy_potato_cat = [i_tag.call('cat-6')]
    @rainbow_puking_cat = [i_tag.call('cat-5')]
    @taco_cat = [i_tag.call('cat-2')]
    @watermelon_cat = [i_tag.call('cat-4')]
    @defuse_cards =
      ['defuse-1','defuse-2','defuse-3','defuse-4','defuse-5']
        .map { |c| i_tag.call(c) }
    @exploding_kitten_cards =
      ['exploding-kitten-1','exploding-kitten-2','exploding-kitten-3']
        .map { |c| i_tag.call(c) }
    @favor_cards = ['favor-1','favor-2'].map { |c| i_tag.call(c) }
    @see_the_future_cards = ['future-1','future-2','future-3']
      .map { |c| i_tag.call(c) }
    @nope_cards = ['nope-1','nope-2'].map { |c| i_tag.call(c) }
    @shuffle_cards = ['shuffle-1','shuffle-2','shuffle-3']
      .map { |c| i_tag.call(c) }
    @skip_cards = ['skip-1','skip-2'].map { |c| i_tag.call(c) }

  end

  def draw
    if @game.can_draw?(current_user)
      card = @game.draw.first
      current_user.hand << card
      current_user.has_drawn = true
      current_user.save!

      @pusher_client.trigger(
        @user_channel,
        'player.hand.updated',
        { card: card.as_json, action: 'add' }
      )

      @game.end_current_turn!
      @pusher_client.trigger(@user_channel, 'player.turn.end', {})


      # tell the next player that it's their turn
      @pusher_client.trigger(
        @game.channel_for_player(@game.current_turn_player),
        'player.turn.start',
        {}
      )
    else
      @pusher_client.trigger(
        @user_channel,
        'player.errors', {
          error: "You can't do that right now."
      })
    end

    render json: {}
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
        @user_channel,
        'player.errors',
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
        'game.player.joined',
        username: current_user.username
      )

      redirect_to @game and return
    end
  end

  def leave
    # change the host if necessary
    if @game.host.id == current_user.id && @game.players.length > 1
      @game.host_id = @game.players.where.not(id: @game.host_id).first
    end

    @game.remove_user(current_user)

    if @game.players.empty?
      @game.end!
    else
      @pusher_client.trigger(
        @main_channel,
        'game.player.left',
        username: current_user.username
      )
    end

    flash[:notice] = 'You have left the game.'
    redirect_to games_path and return
  end

  def send_chat
    @game.players.each do |player|
      @pusher_client.trigger(
        @game.channel_for_player(player),
        'player.chat', {
          message: ActionController::Base.helpers.strip_tags(params[:message]),
          username: player.id == current_user.id ? 'You' : current_user.username
        }
      )
    end

    render json: {}
  end

  private

  def set_game_context
    raise ActionController::RoutingError.new('Bad Request') unless current_user

    @game = Game.find_by_id(params[:id] || params[:game_id])
    raise ActionController::RoutingError.new('Not Found') unless @game
  end

  def set_pusher_context
    @pusher_client = Pusher.default_client
    @main_channel = "game_#{@game.id}_notifications_channel"
    @user_channel = @game.channel_for_player(current_user) if current_user
  end
end
