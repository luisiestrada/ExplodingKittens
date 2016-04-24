class ChatController < ApplicationController

#skip_before_filter  :verify_authenticity_token

  def message
    Pusher.trigger('public-chat', 'message-sent', {
    	user_email: 'test',
    	message: params[:message],
    	timestamp: Time.now()
    });
    render json: {}, status: :ok
  end
end
