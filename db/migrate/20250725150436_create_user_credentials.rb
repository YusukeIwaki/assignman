class CreateUserCredentials < ActiveRecord::Migration[8.0]
  def change
    create_table :user_credentials do |t|
      t.references :user, null: false, foreign_key: true
      t.string :email, null: false
      t.string :password_digest

      t.timestamps
    end
    add_index :user_credentials, :email, unique: true
  end
end
