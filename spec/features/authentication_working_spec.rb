require 'rails_helper'

RSpec.describe 'User Authentication', type: :feature do
  let(:user) { create(:user) }

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

  it 'requires authentication for protected pages' do
    visit authenticated_root_path

    expect(page).to have_current_path(unauthenticated_root_path)
  end

  it 'validates required fields' do
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
