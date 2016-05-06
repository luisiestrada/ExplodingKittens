require 'rails_helper'

RSpec.describe Game, type: :model do
  let(:game) { FactoryGirl.create(:game) }
  let(:user) { FactoryGirl.create(:user) }

  describe 'when joining & leaving games' do
    it 'adds a user' do
      game.add_user(user)
      expect(game.players.count).to eql(1)
    end

    it 'removes a user' do
      game.add_user(user)
      game.remove_user(user)
      expect(game.players.count).to eql(0)
    end

    it 'kicks all players when the game ends' do
      game.add_user(user)
      game.end!
      expect(game.players.count).to eql(0)
    end
  end

  describe 'when the game starts' do
    let(:game_with_players) do
      FactoryGirl.create(:game, :with_users, user_count: 3)
    end

    before(:each) do
      game_with_players.start_game!

      expect(game_with_players.active?).to be_truthy
    end

    it 'a player should be chosen to go first' do
      expect(game_with_players.current_turn_player).to be_truthy
    end

    it 'each player should have 5 cards' do
      game_with_players.players.each { |player| expect(player.hand.count).to eql(5) }
    end

    it 'each player should have 1 defuse card' do
      game_with_players.players.each do |player|
        expect(player.hand.where(card_type: 'defuse').count).to eql(1)
      end
    end

    it 'no player should have an exploding kitten' do
      game_with_players.players.each do |player|
        expect(player.hand
          .where(card_type: 'exploding_kitten')
          .count
        ).to eql(0)
      end
    end
  end

  describe 'player number limits' do
    it 'adds 5 users' do
      users = (1..4).map { FactoryGirl.create(:user) }

      game.add_user(user)
      expect(game.valid_player_count?).to eql(false)

      game.add_user(users.first)
      expect(game.valid_player_count?).to eql(true)

      game.add_user(users.second)
      game.add_user(users.third)
      expect(game.max_players_reached?).to eql(false)

      game.add_user(users.fourth)
      expect(game.players.count).to eql(5)
      expect(game.valid_player_count?).to eql(true)
      expect(game.max_players_reached?).to eql(true)
    end
  end
end
