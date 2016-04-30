class ChatController < ApplicationController

skip_before_filter  :verify_authenticity_token

  def message
    if params[:game_id] then
      pusher_channel = "game_" + params[:game_id] + "_chat"
    else
      pusher_channel = 'public-chat'
    end
    
    Pusher.trigger(pusher_channel, 'message-sent', {
      user_email: current_user.nil? ? 'Unknown' : current_user.email,
    	message: params[:message],
    	timestamp: Time.now(),
    	username: params[:username]
    });
    render json: {}, status: :ok
  end
end
