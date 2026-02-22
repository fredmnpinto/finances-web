class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :validatable, :lockable

  has_many :transactions, dependent: :destroy
  has_many :categories, dependent: :destroy

  after_create :seed_categories

  # Add profile fields for better UX
  validates :first_name, presence: true
  validates :last_name, presence: true

  def full_name
    "#{first_name} #{last_name}"
  end


  private

  def seed_categories
    CategorySeeder.call(self)
  end
end
