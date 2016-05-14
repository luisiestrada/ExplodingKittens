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

    let(:player) { game_with_players.current_turn_player }

    before(:each) do
      game_with_players.start_game!
      expect(game_with_players.active?).to be_truthy
    end

    def assign_card(player, card)
      card.game_id = game_with_players.id
      player.hand << card

      player.save!
    end

    it 'should go to the discard pile' do
      card = PlayingCard.build_from_template(Settings.card_templates.attack.to_h)
      card.game_id = game_with_players.id
      current_player = game_with_players.current_turn_player
      current_player.hand << card
      current_player.save!

      expect(card.state).to eql('hand')
      game_with_players.play_card(current_player, card)
      expect(card.state).to eql('discarded')
    end

    context 'attack card' do
      let(:card) { PlayingCard.build_from_template(Settings.card_templates.attack.to_h) }

      before(:each) { assign_card(player, card) }
      after(:each) { card.destroy! }

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
        victim = game_with_players.next_turn_player

        assign_card(victim, card2)
        expect(victim.turns_to_take).to eql(1)

        # have the current player play their attack card on a victim
        game_with_players.play_card(player, card)
        expect(victim.reload.turns_to_take).to eql(2)

        # have the victim play another attack card on the next player
        game_with_players.play_card(victim, card2)
        expect(victim.reload.turns_to_take).to eql(1)
        expect(game_with_players.current_turn_player.turns_to_take).to eql(2)
      end
    end

    context 'skip card' do
      let(:card) { PlayingCard.build_from_template(Settings.card_templates.skip.to_h) }

      before(:each) { assign_card(player, card) }
      after(:each) { card.destroy! }

      it "skip's the player's turn" do
        next_player = game_with_players.next_turn_player
        game_with_players.play_card(player, card)
        expect(next_player.id).to eql(game_with_players.current_turn_player.id)
      end
    end

    context 'shuffle card' do
      let(:card) { PlayingCard.build_from_template(Settings.card_templates.shuffle.to_h) }

      before(:each) { assign_card(player, card) }
      after(:each) { card.destroy! }

      it 'shuffles the deck' do
        old_deck_order = game_with_players.draw_pile_ids
        game_with_players.play_card(player, card)
        expect(old_deck_order).not_to eql(game_with_players.draw_pile_ids)
      end
    end

    context 'see the future card' do
      let(:card) { PlayingCard.build_from_template(Settings.card_templates.see_the_future.to_h) }

      before(:each) { assign_card(player, card) }
      after(:each) { card.destroy! }

      it 'peeks at the top 3 cards' do
        result = game_with_players.play_card(player, card)
        expect(result[:action][:data] - game_with_players.draw(3)).to eql([])
      end
    end
  end
end
