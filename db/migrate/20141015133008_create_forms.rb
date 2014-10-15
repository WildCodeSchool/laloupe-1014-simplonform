class CreateForms < ActiveRecord::Migration
  def change
  	create_table :forms do |t|
      t.string :email
      t.string :token
      t.string :private_token
    end
	end
end
