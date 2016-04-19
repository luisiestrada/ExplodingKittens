require 'rails_helper'

RSpec.describe User, type: :model do
  before(:each) do
    @user = User.create(email: 'woahbam@sdlfdsf.com', password: 'lsdjflksdjfsd')
  end

  after(:each) do
    @user.destroy!
  end

  describe 'after signup' do
    it 'a random username is generated' do
      expect(@user.username.blank?).to be_falsy
    end

    it 'a UserStat object is generated' do
      expect(@user.stats).to be_truthy
    end

    it 'games played should be 0' do
      expect(@user.games_played).to eql(0)
    end

    it 'win loss ratio should be 0.0' do
      expect(@user.win_loss_ratio).to eql(0.0)
    end
  end
end
