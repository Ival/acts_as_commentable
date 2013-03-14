class CreateComments < ActiveRecord::Migration
  def self.up
    create_table :comments do |t|
      t.integer :app_id, null: false
      t.text :content, null: false
      t.references :commentable, :polymorphic => true, null: false
      t.references :user, null: false
      t.datetime :deleted_at
      t.timestamps
    end

    add_index :comments, :commentable_type
    add_index :comments, :commentable_id
    add_index :comments, :user_id
    add_index :comments, :app_id
  end

  def self.down
    drop_table :comments
  end
end
