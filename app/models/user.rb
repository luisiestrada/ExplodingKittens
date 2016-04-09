class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  belongs_to :game
  has_one :stats, class_name: UserStat

  validates_presence_of :email, :encrypted_password
  before_create :generate_anon_username
  after_create :init_stats

  private

  def generate_anon_username
    self.username = "Anon-#{self.object_id}"
  end

  def init_stats
    UserStat.create(user_id: self.id)
  end
end
