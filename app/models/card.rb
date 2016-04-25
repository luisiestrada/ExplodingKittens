class Card < ActiveRecord::Base
  validates_presence_of :card_type, :default_quantity

  before_create :init_card_name, if: Proc.new { |c| c.card_name.blank? }

  def self.create_from_template(template)
    self.create(template)
  end

  private

  def init_card_name
    self.card_name = self.card_type
  end
end
