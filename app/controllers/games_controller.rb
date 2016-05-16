class GamesController < ApplicationController
  before_filter :set_user_context
  before_filter :set_game_context, except: [:create, :index]
  before_filter :set_pusher_context, except: [:create, :index]
  before_filter :set_player_icons, only: [:show]
  before_filter :set_card_icons, only: [:show]
  before_filter :set_existing_players, only: [:show]

  def index
    @games = Game.with_players
  end

  def create
    if @user
      @game = Game.new
      if params[:game].present?
        room_name = params[:game][:room_name]
        @game.room_name = room_name if room_name.present?
      end

      @game.add_user(@user)

      @game.save!

      set_pusher_context
      flash[:notice] = 'New game!'
      redirect_to @game and return
    else
      flash[:alert] = 'You must be logged in to create a game.'
      redirect_to root_path and return
    end
  end

  def show; end

  def draw
    if @game.active? && @game.can_draw?(@user)
      card = @game.draw.first
      @user.hand << card
      @user.has_drawn = true
      @user.save!

      @pusher.trigger(
        @user_channel,
        'player.hand.updated',
        { card: card.as_json, action: 'add' }
      )

      if @user.turns_to_take > 1
        @user.turns_to_take -= 1
        @user.save!
        @pusher.trigger(@user_channel, 'announcement', {
          message: "It's still your turn!"
        })
      else
        @game.end_current_turn!
        @pusher.trigger(@user_channel, 'player.turn.end', {})

        send_turn_start_event
      end
    else
      send_action_error
    end

    render json: {}
  end

  def play_card
    # make sure it's the players turn or they have an interrupt card
    # make sure the player owns the card

    card = PlayingCard.find_by_id(params[:card_id])

    if card
      target_player = User.find_by_id(params[:target_player_id])
      result = @game.play_card(@user, card, target_player: target_player)

      if result[:card_was_played]
        @game.players.where.not(id: @user.id).each do |player|
          @pusher.trigger(
            @game.channel_for_player(player),
            'announcement', {
              message: result[:global_announcements]
          })
        end

        @pusher.trigger(
          @user_channel, 'announcement', {
            message: result[:player_announcements]
        })

        @pusher.trigger(
          @user_channel, 'player.hand.updated', {
            card_id: card.id,
            action: 'remove'
        })

        # some cards return more data
        if result[:action][:data]
          case result[:action][:key]
          when 'see_the_future'
            @pusher.trigger(@user_channel, 'player.deck.see_the_future', {
              cards: result[:action][:data].as_json
            })
          when 'favor'
            @pusher.trigger(@game.channel_for_player(target_player),
              'player.steal_card_favor', {
                username: @user.username,
                id: @user.id
            })
          end
        end

        # some cards cause the player to end their turn
        if @user.id != @game.current_turn_player.id
          @pusher.trigger(@user_channel, 'player.turn.end', {})

          send_turn_start_event
        end
      else
        send_action_error
      end
    elsif card.nil?
      send_action_error("You don't have that card.")
    else
      send_action_error
    end

    render json: {}
  end

  def give_card_to_thief
    # This action exclusively for when a player is a victim of a favor card
    # ...definitely bad design.

    # Getting lazy here, just going to trust that the victim hasn't modified
    # the original player id of the favor card.

    victim = @user
    favor_player = User.find_by_id(params[:favor_player_id])

    stolen_card = victim.hand.find(params[:target_card_id])
    favor_player.hand << stolen_card
    favor_player.save!

    @pusher.trigger(@game.channel_for_player(favor_player), 'announcement', {
      message: "You received a #{stolen_card.card_type} card from #{victim.username}!"
    })

    @pusher.trigger(
      @game.channel_for_player(favor_player),
      'player.hand.updated', {
        card: stolen_card.as_json,
        action: 'add'
    })

    @pusher.trigger(@user_channel, 'announcement', {
      message: "You gave up a #{stolen_card.card_type} card!"
    })

    render json: {}
  end

  def start
    if @game.valid_player_count? && !@game.active?
      @game.start_game!

      # send basic info about all players in game, (ids, usernames)
      @pusher.trigger(@main_channel, 'game.start', @game.as_json)

      # tell each player what hand they have...1 card at a time
      # Pusher limits the size of data sent at one time to 10kB
      @game.players.each do |player|
        player.hand.each do |card|
          @pusher.trigger(
            @game.channel_for_player(player),
            'player.hand.updated',
            { card: card.as_json, action: 'add' }
          )
        end
      end

      send_turn_start_event
    else
      @pusher.trigger(
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
      @game.add_user(@user)
      flash[:notice] = "You have joined game ##{@game.id}!"
      @pusher.trigger(
        @main_channel,
        'game.player.joined',
        id: @user.id,
        username: @user.username
      )

      redirect_to @game and return
    end
  end

  def leave
    # change the host if necessary
    if @game.host_id == @user.id && @game.players.length > 1
      @game.host_id = @game.players.where.not(id: @game.host_id).first
    end

    @game.remove_user(@user)

    if @game.players.empty?
      @game.end!
    else
      @pusher.trigger(
        @main_channel,
        'game.player.left',
        username: @user.username,
        id: @user.id
      )
    end

    flash[:notice] = 'You have left the game.'
    redirect_to games_path and return
  end

  def send_chat
    @game.players.each do |player|
      @pusher.trigger(
        @game.channel_for_player(player),
        'player.chat', {
          message: ActionController::Base.helpers.strip_tags(params[:message]),
          username: player.id == @user.id ? 'You' : @user.username
        }
      )
    end

    render json: {}
  end

  private

  def set_user_context
    @user = current_user
  end

  def set_game_context
    raise ActionController::RoutingError.new('Bad Request') unless @user

    @game = Game.find_by_id(params[:id] || params[:game_id])
    raise ActionController::RoutingError.new('Not Found') unless @game
  end

  def set_pusher_context
    @pusher = Pusher.default_client
    @main_channel = "game_#{@game.id}_notifications_channel"
    @user_channel = @game.channel_for_player(@user) if @user
  end

  def set_existing_players
    @other_players = @game.players.where.not(id: @user.id)
  end

  def set_player_icons
    @player_icons = [
      'playericon1.png', 'playericon2.png', 'playericon3.png',
      'playericon4.png', 'playericon7.png'
    ]
  end

  def set_card_icons
    # get image tags for all the card assets
    @attack_cards =
      ['attack-1','attack-2','attack-3','attack-4']

    @beard_cat = ['cat-3']
    @hairy_potato_cat = ['cat-6']
    @rainbow_puking_cat = ['cat-5']
    @taco_cat = ['cat-2']
    @watermelon_cat = ['cat-4']
    @defuse_cards =
      ['defuse-1','defuse-2','defuse-3','defuse-4','defuse-5']

    @exploding_kitten_cards =
      ['exploding-kitten-1','exploding-kitten-2','exploding-kitten-3']

    @favor_cards = ['favor-1','favor-2']
    @see_the_future_cards = ['future-1','future-2','future-3']

    @nope_cards = ['nope-1','nope-2']
    @shuffle_cards = ['shuffle-1','shuffle-2','shuffle-3']

    @skip_cards = ['skip-1','skip-2']
  end

  def send_action_error(err=nil)
    @pusher.trigger(
      @user_channel,
      'player.errors', {
        error: err || "You can't do that right now."
    })
  end

  def send_turn_start_event
    @pusher.trigger(
      @game.channel_for_player(@game.current_turn_player),
      'player.turn.start',
      { for_self: true }
    )

    @game.players.where.not(id: @game.current_turn_player.id).each do |player|
      @pusher.trigger(
        @game.channel_for_player(player),
          'player.turn.start', {
            player_id: @game.current_turn_player.id,
            username: @game.current_turn_player.username
        })
    end
  end
end
