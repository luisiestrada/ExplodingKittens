class PlayingCard < Card
  belongs_to :player, class_name: User
  belongs_to :game

  before_save :set_state

  @discarded = false

  attr_writer :discarded

  def discarded?
    @discarded || self.state == 'discarded'
  end

  private

  def set_state
    if self.player.present?
      self.state = 'hand'
    elsif self.discarded?
      self.state = 'discarded'
    end
  end
end
