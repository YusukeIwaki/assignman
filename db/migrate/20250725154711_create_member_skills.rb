class CreateMemberSkills < ActiveRecord::Migration[8.0]
  def change
    create_table :member_skills do |t|
      t.references :member, null: false, foreign_key: true
      t.references :skill, null: false, foreign_key: true

      t.timestamps
    end
  end
end
