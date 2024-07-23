# frozen_string_literal: true

class RemoveIdxProjectStatisticsPackagesSizeAndProjectIdSync < Gitlab::Database::Migration[2.2]
  milestone '17.3'
  disable_ddl_transaction!

  INDEX_NAME = 'index_project_statistics_on_packages_size_and_project_id'
  COLUMNS = %i[packages_size project_id]

  def up
    return unless should_run?

    remove_concurrent_index_by_name :project_statistics, name: INDEX_NAME
  end

  def down
    return unless should_run?

    add_concurrent_index :project_statistics, COLUMNS, name: INDEX_NAME
  end

  def should_run?
    Gitlab.com_except_jh?
  end
end
