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

  describe 'when given to a player' do
    it 'the state should change to "hand"' do
      @player.hand << @card
      @player.save!

      expect(@card.state).to eql('hand')
      expect(@card.player).to eql(@player)
    end
  end
end
