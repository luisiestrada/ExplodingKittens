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
      expect(user.game_id).to eql(nil)
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

    after(:each) do
      game_with_players.destroy!
    end

    it 'a player should be chosen to go first' do
      expect(game_with_players.current_turn_player).to be_truthy
      expect(game_with_players.turn_orders[0]).to eql(game_with_players.current_turn_player.id)
      expect(game_with_players.turn_orders.keys.length).to eql(3)
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

  describe 'playing a card' do
    let(:game_with_players) do
      FactoryGirl.create(:game, :with_users, user_count: 3)
    end

    before(:each) do
      game_with_players.start_game!
      expect(game_with_players.active?).to be_truthy
    end

    # it 'should go to the discard pile' do
    #   game_with_players
    #   game_with_players.play_card(game_with_players.)
    # end

    context 'attack card' do
      let(:card) { PlayingCard.build_from_template(Settings.card_templates.attack.to_h) }
      let(:player) { game_with_players.current_turn_player }

      before(:each) do
        card.game_id = game_with_players.id
        game_with_players.current_turn_player.hand << card
        game_with_players.current_turn_player.save!
      end

      after(:each) do
        card.destroy!
      end

      it "should end the current player's turn" do
        game_with_players.play_card(player, card)
        expect(game_with_players.current_turn_player.id).not_to eql(player.id)
      end

      it 'the next player should have 2 turns to take' do
        next_player = game_with_players.next_turn_player
        game_with_players.play_card(player, card)

        expect(next_player.reload.turns_to_take).to eql(2)
        expect(next_player.id).to eql(game_with_players.current_turn_player.id)
      end

      it 'an attack card victim who plays the same card should have their turn end immediately' do
        card2 = PlayingCard.build_from_template(Settings.card_templates.attack.to_h)
        card.game_id = game_with_players.id
        card.user_id = game_with_players.next_turn_player.id
        game_with_players.next_turn_player.save!

        # have the current player play their attack card on a victim
        game_with_players.play_card(player, card)
        victim = game_with_players.current_turn_player
        expect(victim.turns_to_take).to eql(2)

        # have the victim play another attack card on the next player
        game_with_players.play_card(victim, card)
        expect(victim.turns_to_take).to eql(1)
        expect(game_with_players.current_turn_player.turns_to_take).to eql(2)
      end
    end
  end
end
