---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Configure large language models for GitLab Duo features.
title: GitLab Duo model selection
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Core, Pro or Enterprise
- Offering: GitLab.com
- Available on [GitLab Duo with self-hosted models](../../administration/gitlab_duo_self_hosted/_index.md): No
- Status: Private beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/17570) for top-level groups in GitLab 18.1 with a [flag](../../administration/feature_flags/_index.md) named `ai_model_switching`. Disabled by default.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

To help meet your performance and compliance requirements,
on GitLab.com, you can choose to use different large language models (LLMs) with GitLab Duo.

If you do not select a specific LLM, all GitLab Duo features use the default LLMs.
You should use the defaults if you do not have unique requirements.

## Select an LLM for a feature

Prerequisites:

- The group that you want to select LLMs for must:
  - Be a [top-level group](../group/_index.md#group-hierarchy) on GitLab.com.
  - Have GitLab Duo Core, Pro, or Enterprise enabled.
- You must have the Owner role for the group.
- In GitLab 18.3 or later, you must [assign a default namespace](#assign-a-default-gitlab-duo-namespace) if you belong to multiple GitLab Duo namespaces.

To select a different LLM for a feature:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > GitLab Duo**.

   If you **GitLab Duo** is not visible, ensure you have GitLab Duo Core, Pro or Enterprise turned on for the group.
1. Select **Configure features**.
1. For the feature you want to configure, select an LLM from the dropdown list.

![The GitLab UI for selecting a model.](img/configure_model_selections_v18_1.png)

## Assign a default GitLab Duo namespace

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/552081) in GitLab 18.3.

{{< /history >}}

If you belong to multiple GitLab Duo namespaces, you must choose one as your default namespace.

You must do this because GitLab Duo might not be able to automatically detect the namespace you are working from, and therefore the LLMs you want to use. For example, when:

- Using GitLab Duo in the CLI.
- A new project has not been initialised with Git, so the IDE cannot identify an associated namespace.

If this happens, GitLab Duo uses the LLMs you have selected in your default namespace.

To select a default namespace:

1. On the left sidebar, select your avatar.
1. Select **Preferences**.
1. Go to the **Behavior** section.
1. From the **Default GitLab Duo group** dropdown list, select the namespace to set as your default.
1. Select **Save changes**.

## Troubleshooting

When selecting models other than the default, you might encounter the following issues.

### LLM is not available

If you are using the GitLab Default LLM for a GitLab Duo AI-native feature, GitLab might change the default LLM without notifying the user to maintain optimal performance and reliability.

If you have selected a specific LLM for a GitLab Duo AI-native feature, and that LLM is not available, there is no automatic fallback, and the feature that uses this LLM is unavailable.

### Latency issues with code completion

If you are assigned a seat in a project that has a specific LLM selected for [code completion](../project/repository/code_suggestions/_index.md#code-completion-and-generation):

- Your IDE extension disables the [direct connection to the AI gateway](../../administration/gitlab_duo/gateway.md#region-support).
- Code completion requests go through the GitLab monolith, which then selects the specified model to respond to these requests.

This might cause increased latency with code completion requests.

### Agentic Chat incompatibility

When a specific LLM is selected for GitLab Duo Chat or its sub-features, [GitLab Duo Agentic Chat](../gitlab_duo_chat/agentic_chat.md) is not available in that namespace.
