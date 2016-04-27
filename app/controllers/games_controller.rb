class GamesController < ApplicationController
  skip_before_filter  :verify_authenticity_token
  
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
      @game_push_channel_name = "game_" + @game.id.to_s + "_notifications_channel"
      @game_chat_channel_name = "game_" + @game.id.to_s + "_chat"
  end
  
  def play_turn
    @game = Game.find(params[:game_id])
    game_channel = "game_" + @game.id.to_s + "_notifications_channel"
    Pusher.trigger(game_channel, 'next_turn', {
      user_id: params[:user_id],
      username: params[:username]
    });
    render json: {}, status: :ok
  end
end