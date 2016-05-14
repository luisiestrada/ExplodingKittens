class PlayingCard < Card
  belongs_to :player, class_name: User, foreign_key: :user_id
  belongs_to :game

  before_save :set_state
  attr_writer :discarded
  attr_reader :discarded

  private

  def set_state
    if self.user_id.present?
      self.state = 'hand'
    else
      self.state = discarded ? 'discarded' : 'deck'
    end
  end
end
