require 'rails_helper'

RSpec.describe 'Authentication Feature Test', type: :feature do
  let(:user) { create(:user, confirmed_at: Time.current) }

  before do
    visit new_user_session_path
    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password
    click_button 'Sign in'
  end

  it 'allows authenticated user to access protected areas' do
    sign_in user
    visit authenticated_root_path

    expect(page).to have_content('Dashboard')
    expect(page).to have_content(user.email)
    expect(page).not_to have_content('Sign In')
  end
end
