# frozen_string_literal: true

class AddMergeRequestsApprovalRulesMrsApprovalRuleFk < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :merge_requests_approval_rules_merge_requests, :merge_requests_approval_rules,
      column: :approval_rule_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :merge_requests_approval_rules_merge_requests, column: :approval_rule_id
    end
  end
end
