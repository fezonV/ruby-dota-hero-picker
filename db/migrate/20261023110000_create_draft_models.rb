class CreateDraftModels < ActiveRecord::Migration[8.1]
  def change
    create_table :heroes do |t|
      t.string :name, null: false
      t.string :role, null: false
      t.integer :support, null: false, default: 0
      t.integer :control, null: false, default: 0
      t.integer :damage, null: false, default: 0
      t.integer :durability, null: false, default: 0
      t.timestamps
    end
    add_index :heroes, "lower(name)", unique: true, name: "index_heroes_on_lower_name"
    add_check_constraint :heroes, "length(trim(name)) > 0", name: "heroes_name_present"
    add_check_constraint :heroes, "length(trim(role)) > 0", name: "heroes_role_present"
    %w[support control damage durability].each do |feature|
      add_check_constraint :heroes, "#{feature} BETWEEN 0 AND 3", name: "heroes_#{feature}_range"
    end

    create_table :drafts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.timestamps
    end
    add_check_constraint :drafts, "length(trim(title)) BETWEEN 1 AND 100", name: "drafts_title_length"

    create_table :draft_picks do |t|
      t.references :draft, null: false, foreign_key: true
      t.references :hero, null: false, foreign_key: true
      t.string :team, null: false
      t.integer :position, null: false
      t.timestamps
    end
    add_index :draft_picks, [ :draft_id, :hero_id ], unique: true
    add_index :draft_picks, [ :draft_id, :team, :position ], unique: true
    add_check_constraint :draft_picks, "team IN ('ally', 'enemy')", name: "draft_picks_team_valid"
    add_check_constraint :draft_picks, "position BETWEEN 1 AND 5", name: "draft_picks_position_range"
  end
end
