require 'rails_helper'

DUMB_PASSWORD = 'lsdjflksdjfsd'
DUMB_EMAIL = 'woahbam@sdlfdsf.com'

RSpec.describe PlayingCard, type: :model do
  before(:each) do
    @player = User.create(email: DUMB_EMAIL, password: DUMB_PASSWORD)
    @card = PlayingCard.build_from_template(Settings.card_templates.attack.to_h)
    @game = Game.create

    @game.playing_cards << @card
    @card.save!

    expect(@card.state).to eql('deck')
  end

  after(:each) do
    @player.destroy!
    @game.destroy!
    @card.destroy!
  end

  describe 'when put in' do
    it "a player's hand the state should be 'hand'" do
      @player.hand << @card

      expect(@card.state).to eql('hand')
      expect(@card.player).to eql(@player)
    end

    it "the discard pile the state should be 'discarded'" do
      @card.discarded = true
      @card.save!
      expect(@card.state).to eql('discarded')
    end
  end
end
