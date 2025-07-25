class CreateUserProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :user_profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.text :bio
      t.string :avatar_url

      t.timestamps
    end
  end
end
