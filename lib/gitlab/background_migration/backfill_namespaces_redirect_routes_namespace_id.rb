# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillNamespacesRedirectRoutesNamespaceId < BatchedMigrationJob
      operation_name :backfill_namespaces_redirect_routes_namespace_id
      feature_category :groups_and_projects

      scope_to ->(relation) { relation.where(source_type: 'Namespace', namespace_id: nil) }

      def perform
        each_sub_batch do |sub_batch|
          redirect_route_with_source = sub_batch
            .joins('inner join namespaces on redirect_routes.source_id = namespaces.id')
            .select(:id, 'namespaces.id as source_namespace_id')

          connection.execute(<<~SQL)
            WITH redirect_route_with_source AS (#{redirect_route_with_source.to_sql})
            UPDATE redirect_routes
            SET namespace_id = redirect_route_with_source.source_namespace_id
            FROM redirect_route_with_source
            WHERE redirect_routes.id = redirect_route_with_source.id
          SQL
        end
      end
    end
  end
end
