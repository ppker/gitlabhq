# frozen_string_literal: true

class IndexIssuableResourceLinksOnNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.7'
  disable_ddl_transaction!

  INDEX_NAME = 'index_issuable_resource_links_on_namespace_id'

  def up
    add_concurrent_index :issuable_resource_links, :namespace_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :issuable_resource_links, INDEX_NAME
  end
end
