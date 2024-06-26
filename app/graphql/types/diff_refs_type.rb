# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  # Types that use DiffRefsType should have their own authorization
  class DiffRefsType < BaseObject
    graphql_name 'DiffRefs'

    field :base_sha, GraphQL::Types::String, null: true,
      description: 'Merge base of the branch the comment was made on.'
    field :head_sha, GraphQL::Types::String, null: false,
      description: 'SHA of the HEAD at the time the comment was made.'
    field :start_sha, GraphQL::Types::String, null: false,
      description: 'SHA of the branch being compared against.'
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
