class PlayingCard < Card
  belongs_to :player
  belongs_to :game

  before_save :set_state

  attr_accessible :discarded

  def discarded?
    self.discarded || self.state == 'discarded'
  end

  private

  def set_state
  if self.user.present?
    self.state = 'hand'
  elsif self.discarded?
    self.state = 'discarded'
  end

end
