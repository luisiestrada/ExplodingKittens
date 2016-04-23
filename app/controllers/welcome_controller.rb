class WelcomeController < ApplicationController
  before_action :authenticate_user!

  def index
  end

  def card_list
  end
  
end
