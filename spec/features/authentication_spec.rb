require 'rails_helper'

RSpec.describe 'User Authentication', type: :feature do
  let(:user) { create(:user) }

  describe 'User Registration' do
    it 'allows a new user to sign up' do
      visit new_user_registration_path

      fill_in 'First name', with: 'John'
      fill_in 'Last name', with: 'Doe'
      fill_in 'Email', with: 'john.doe@example.com'
      fill_in 'Password', with: 'Password123!'
      fill_in 'Password confirmation', with: 'Password123!'

      click_button 'Sign up'

      expect(page).to have_text('A message with a confirmation link has been sent to your email address')
      expect(current_path).to eq(unauthenticated_root_path)
    end

    it 'validates required fields on registration' do
      visit new_user_registration_path

      click_button 'Sign up'

      expect(page).to have_text("First name can't be blank")
      expect(page).to have_text("Last name can't be blank")
      expect(page).to have_text("Email can't be blank")
      expect(page).to have_text("Password can't be blank")
    end

    it 'validates email format' do
      visit new_user_registration_path

      fill_in 'First name', with: 'John'
      fill_in 'Last name', with: 'Doe'
      fill_in 'Email', with: 'invalid-email'
      fill_in 'Password', with: 'Password123!'
      fill_in 'Password confirmation', with: 'Password123!'

      click_button 'Sign up'

      expect(page).to have_text('Email is invalid')
    end

    it 'validates password confirmation' do
      visit new_user_registration_path

      fill_in 'First name', with: 'John'
      fill_in 'Last name', with: 'Doe'
      fill_in 'Email', with: 'john.doe@example.com'
      fill_in 'Password', with: 'Password123!'
      fill_in 'Password confirmation', with: 'DifferentPassword'

      click_button 'Sign up'

      expect(page).to have_text("Password confirmation doesn't match Password")
    end
  end

  describe 'User Sign In' do
    it 'allows an existing user to sign in' do
      user.update!(confirmed_at: Time.current)
      visit new_user_session_path

      fill_in 'Email', with: user.email
      fill_in 'Password', with: user.password

      click_button 'Sign in'

      expect(page).to have_content('Dashboard')
      expect(current_path).to eq(authenticated_root_path)
    end

    it 'validates credentials on sign in' do
      visit new_user_session_path

      fill_in 'Email', with: user.email
      fill_in 'Password', with: 'wrong_password'

      click_button 'Sign in'

      expect(page).to have_text('Invalid email or password')
      expect(current_path).to eq(new_user_session_path)
    end

    it 'shows error for unconfirmed user' do
      unconfirmed_user = create(:user, :unconfirmed)
      visit new_user_session_path

      fill_in 'Email', with: unconfirmed_user.email
      fill_in 'Password', with: unconfirmed_user.password

      click_button 'Sign in'

      expect(page).to have_text('You have to confirm your email address before continuing')
    end
  end

  describe 'User Sign Out' do
    it 'allows a signed in user to sign out' do
      sign_in user
      visit authenticated_root_path

      # Find and click the sign out button in the dropdown
      find('.group-hover\\:visible button').click

      expect(page).to have_content('Sign In')
      expect(current_path).to eq(unauthenticated_root_path)
    end
  end

  describe 'Navigation' do
    it 'shows sign in and sign up links to unauthenticated users' do
      visit unauthenticated_root_path

      expect(page).to have_link('Get Started')
      expect(page).to have_link('Sign In')
    end

    it 'shows authenticated navigation to signed in users' do
      sign_in user
      visit authenticated_root_path

      expect(page).to have_link('Dashboard')
      expect(page).to have_link('Transactions')
      expect(page).to have_content(user.full_name)
      expect(page).to have_content(user.email)
    end
  end

  private

  def sign_in(user)
    visit new_user_session_path
    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password
    click_button 'Sign in'
  end
end
