require 'rails_helper'

RSpec.describe Game, type: :model do
  before(:each) do
    @user = User.create(email: 'woahbam@sdlfdsf.com', password: 'lsdjflksdjfsd')
    @game = Game.create
  end

  after(:each) do
    @user.destroy!
    @game.destroy!
  end

  describe 'joining & leaving games' do
    it 'adds a user' do
      @game.add_user(@user)
      expect(@game.players.count).to eql(1)
    end

    it 'removes a user' do
      @game.add_user(@user)
      @game.remove_user(@user)
      expect(@game.players.count).to eql(0)
    end

    it 'kicks all players when the game ends' do
      @game.add_user(@user)
      @game.end!
      expect(@game.players.count).to eql(0)
    end
  end
end
