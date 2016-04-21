class ChatController < ApplicationController
  def message
    puts params[:message]
  end
end
