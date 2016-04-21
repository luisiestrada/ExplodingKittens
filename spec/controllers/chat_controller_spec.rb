require 'rails_helper'

RSpec.describe ChatController, type: :controller do

  describe "GET #message" do
    it "returns http success" do
      get :message
      expect(response).to have_http_status(:success)
    end
  end

end
