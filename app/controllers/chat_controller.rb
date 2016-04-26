class ChatController < ApplicationController

skip_before_filter  :verify_authenticity_token

  def message
    if params[:game_id] then
      pusher_channel = "game-" + params[:game_id] + "-chat"
    else
      pusher_channel = 'public-chat'
    end
    
    Pusher.trigger(pusher_channel, 'message-sent', {
    	user_email: 'test',
    	message: params[:message],
    	timestamp: Time.now()
    });
    render json: {}, status: :ok
  end
end
