
FactoryGirl.define do
	factory :user do
		sequence(:name) { |n| "Person #{n}" }
		sequence(:email) { |n| "Person_#{n}@example.com" }
		password 			  '6yhn6yhn'
		password_confirmation '6yhn6yhn'

		factory :admin do
			admin true
		end
	end
end