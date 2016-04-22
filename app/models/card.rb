class Card < ActiveRecord::Base
  validates_presence_of :card_type, :default_quantity

  before_create :init_card_name, if: Proc.new { |c| c.card_name.blank? }

  def self.create_from_template(template)
    card = self.new

    template['card_attributes'].each_key do |attribute|
      card.send("#{attribute}=", template['card_attributes'][attribute])
    end

    card.default_quantity = template['default_quantity']
    card.save!
  end

  private

  def init_card_name
    self.card_name = self.card_type
  end
end
