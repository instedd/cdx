class AddKindToInstitutions < ActiveRecord::Migration
  def change
    add_column :institutions, :kind, :string, default: "institution"
  end
end
