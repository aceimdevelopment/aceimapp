class CreateGeneralParameters < ActiveRecord::Migration[5.2]
  def change
    create_table :general_parameters do |t|
      t.text :value

      t.timestamps
    end
    reversible do |direction|
      direction.up { execute('ALTER TABLE general_parameters ALTER COLUMN id TYPE varchar (50), ALTER COLUMN id SET NOT NULL, ALTER COLUMN id DROP DEFAULT')}
    end   
  end
end
