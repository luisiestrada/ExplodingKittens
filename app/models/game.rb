class Game < ActiveRecord::Base
  belongs_to :winner, class_name: User
  has_many :users
  has_many :stats, class_name: GameStat

  alias :players :users

  MIN_PLAYERS = 2
  MAX_PLAYERS = 5

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :by_winner, -> (user) { where(winner_id: user.id) }

  def add_user(user)
    return false unless self.users.count < MAX_PLAYERS
    
    self.users << user
    self.save!
  end

  def remove_user(user)
    self.users.delete(user)
  end

  def end!
    self.users.delete_all
  end

  def valid_player_count?
    self.players.count.between?(MIN_PLAYERS, MAX_PLAYERS)
  end
  
  def max_players_reached?
    return self.users.count == MAX_PLAYERS
  end
end
