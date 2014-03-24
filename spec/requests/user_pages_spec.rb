require 'spec_helper'

describe "User pages" do

	subject { page }

	describe "index" do
		let(:user) { FactoryGirl.create(:user) }
		before do
			valid_signin user
			visit users_path
		end

		it { should have_title('All users') }
		it { should have_content('All users') }

		describe "pagination" do 
			before(:all) do
				User.delete_all
				30.times {FactoryGirl.create(:user) } 
			end
			after(:all) { User.delete_all }

			it { should have_selector('div.pagination') }

			it "should list each user" do
				User.paginate(page: 1).each do |user|
					expect(page).to have_selector('li', text: user.name)
				end
			end
		end

		describe "delete links" do
			it { should_not have_link('delete') }

			describe "as an admin user" do
				let(:admin) { FactoryGirl.create(:admin) }
				before do
					valid_signin admin
					visit users_path
				end

				it { should have_link('delete', href: user_path(User.first)) }
				it "should be able to delete another user" do
					expect do
						click_link('delete', match: :first)
					end.to change(User, :count).by(-1)
				end
				it { should_not have_link('delete', href: user_path(admin)) }
			end
		end
	end


	describe "signup page" do
		before { visit signup_path }
		let(:submit) { "Create my account" }

		it { should have_content('Sign up') }
		it { should have_title(full_title('Sign up')) }

		describe "with invalid information" do
			it "should not create a user" do
				expect { click_button submit }.not_to change(User, :count)
			end
			
			describe "after submission" do
				before { click_button submit }

				it { should have_title('Sign up') }
				it { should have_content("* Name can't be blank") }
				it { should have_content("* Email can't be blank") }
				it { should have_content("* Email is invalid") }
				it { should have_content("* Password is too short (minimum is 6 characters)") }
				it { should have_content("* Password can't be blank") }
			end
			describe "when password confirmation doesn't match password"
			before do
				fill_in "Password", with: "hahahaha"
				click_button submit
			end
			it { should have_content("* Password confirmation doesn't match Password")}
		end

		describe "with valid information" do
			before { valid_signup(FactoryGirl.create(:user)) }

			it "should create a user" do
				expect { click_button submit }.to change(User, :count).by(1)
			end
			describe "after saving the user" do
				before { click_button submit }
				let(:user) { User.find_by(email: 'user@example.com') }

				it { should have_title(user.name) }
				it { should have_selector('div.alert.alert-success', text: 'Welcome') }
				it { should have_link('Sign out',    href: signout_path) }
				
				
			end
		end
	end

	describe "profile page" do 
		let (:user) { FactoryGirl.create(:user) }
		let!(:m1) { FactoryGirl.create(:micropost, user: user, content: "Foo") }
		let!(:m2) { FactoryGirl.create(:micropost, user: user, content: "Bar") }

		before{ visit user_path(user)}

		it {should have_content(user.name)}
		it {should have_title(user.name)}

		describe "micropost" do
			it { should have_content(m1.content) }
			it { should have_content(m2.content) }
			it { should have_content(user.microposts.count) }
		end

		describe "follow/unfollow buttons" do
      let(:other_user) { FactoryGirl.create(:user) }
      before { valid_signin user }

      describe "following a user" do
        before { visit user_path(other_user) }

        it "should increment the followed user count" do
          expect do
            click_button "Follow"
          end.to change(user.followed_users, :count).by(1)
        end

        it "should increment the other user's followers count" do
          expect do
            click_button "Follow"
          end.to change(other_user.followers, :count).by(1)
        end

        describe "toggling the button" do
          before { click_button "Follow" }
          it { should have_xpath("//input[@value='Unfollow']") }
        end
      end

      describe "unfollowing a user" do
        before do
          user.follow!(other_user)
          visit user_path(other_user)
        end

        it "should decrement the followed user count" do
          expect do
            click_button "Unfollow"
          end.to change(user.followed_users, :count).by(-1)
        end

        it "should decrement the other user's followers count" do
          expect do
            click_button "Unfollow"
          end.to change(other_user.followers, :count).by(-1)
        end

        describe "toggling the button" do
          before { click_button "Unfollow" }
          it { should have_xpath("//input[@value='Follow']") }
        end
      end
    end
	end

	describe "edit" do
		let(:user) { FactoryGirl.create(:user) }
		before do 
			valid_signin user
			visit edit_user_path(user) 
		end

		describe "page" do
			it { should have_content("Update your profile") }
			it { should have_title("Edit user") }
			it { should have_link('change', href: 'http://gravatar.com/emails') }
		end

		describe "with invalid information" do
			before { click_button "Save changes" }

			it { should have_content('error') }
		end
		describe "with valid information" do
			let(:new_name) { "New Name" }
			let(:new_email) { "new@example.com" }
			before do 
				fill_in "Name",             with: new_name
				fill_in "Email",            with: new_email
				fill_in "Password",         with: user.password
				fill_in "Confirmation", with: user.password
				click_button "Save changes"
			end

			it { should have_title(new_name) }
			it { should have_selector('div.alert.alert-success') }
			it { should have_link('Sign out', href: signout_path) }
			specify { expect(user.reload.name).to eq new_name }
			specify { expect(user.reload.email).to eq new_email }
		end

		describe "forbidden attributes" do
			let(:params) do
				{ user: { admin:true, password: user.password, password_confirmation:user.password}}
			end

			before do 
				valid_signin user, no_capybara:true
				patch user_path(user), params
			end
			specify { expect(user.reload).not_to be_admin }
		end
	end
end