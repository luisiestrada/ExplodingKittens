class WelcomeController < ApplicationController
  before_action :authenticate_user!

  def index
  end

  def card_list
  end

  def instructions
  end

  def about_us
  end

end
