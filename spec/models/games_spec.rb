require 'rails_helper'

DUMB_PASSWORD = 'lsdjflksdjfsd'
DUMB_EMAIL = 'woahbam@sdlfdsf.com'

RSpec.describe Game, type: :model do
  before(:each) do
    @user = User.create(email: DUMB_EMAIL, password: DUMB_PASSWORD)
    @user2 = User.create(email: 'woahbam2@sdlfdsf.com', password: 'lsdjflksdjfsd')
    @user3 = User.create(email: 'woahbam3@sdlfdsf.com', password: 'lsdjflksdjfsd')
    @user4 = User.create(email: 'woahbam4@sdlfdsf.com', password: 'lsdjflksdjfsd')
    @user5 = User.create(email: 'woahbam5@sdlfdsf.com', password: 'lsdjflksdjfsd')
    @game = Game.create
  end

  after(:each) do
    @user.destroy!
    @user2.destroy!
    @user3.destroy!
    @user4.destroy!
    @user5.destroy!
    @game.destroy!
  end

  describe 'when joining & leaving games' do
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

  describe 'when the game starts' do
    let(:users) {
      users = [@user]
      3.times { users << User.create(email: DUMB_EMAIL, password: DUMB_PASSWORD) }
      users
    }

    before(:each) do
      @game.players + users
      @game.start_game

      expect(@game.active?).to be_truthy
    end

    it 'each player should have 5 cards' do
      @game.players.each { |player| expect(player.hand.count).to eql(5) }
    end

    it 'each player should have 1 defuse card' do
      @game.players.each do |player|
        expect(player.hand.where(card_type: 'defuse').count).to eql(1)
      end
    end

    it 'no player should have an exploding kitten' do
      @game.players.each do |player|
        expect(player.hand
          .where(card_type: 'exploding_kitten')
          .count
        ).to eql(0)
      end
    end
  end

  describe 'player number limits' do
    it 'adds 5 users' do
      @game.add_user(@user)
      expect(@game.valid_player_count?).to eql(false)
      @game.add_user(@user2)
      expect(@game.valid_player_count?).to eql(true)
      @game.add_user(@user3)
      @game.add_user(@user4)
      expect(@game.max_players_reached?).to eql(false)
      @game.add_user(@user5)
      expect(@game.players.count).to eql(5)
      expect(@game.valid_player_count?).to eql(true)
      expect(@game.max_players_reached?).to eql(true)
    end
  end
end
