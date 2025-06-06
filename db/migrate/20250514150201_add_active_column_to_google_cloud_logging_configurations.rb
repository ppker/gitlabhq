# frozen_string_literal: true

class AddActiveColumnToGoogleCloudLoggingConfigurations < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  def up
    add_column :audit_events_google_cloud_logging_configurations, :active, :boolean, null: false, default: true
  end

  def down
    remove_column :audit_events_google_cloud_logging_configurations, :active
  end
end
