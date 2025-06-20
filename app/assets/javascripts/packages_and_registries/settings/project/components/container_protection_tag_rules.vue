<script>
import {
  GlAlert,
  GlBadge,
  GlButton,
  GlDrawer,
  GlLoadingIcon,
  GlModal,
  GlModalDirective,
  GlSprintf,
  GlTable,
  GlTooltipDirective,
  GlSkeletonLoader,
} from '@gitlab/ui';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import ContainerProtectionTagRuleForm from 'ee_else_ce/packages_and_registries/settings/project/components/container_protection_tag_rule_form.vue';
import getContainerProtectionTagRulesQuery from '~/packages_and_registries/settings/project/graphql/queries/get_container_protection_tag_rules.query.graphql';
import deleteContainerProtectionTagRuleMutation from '~/packages_and_registries/settings/project/graphql/mutations/delete_container_protection_tag_rule.mutation.graphql';
import { __, s__ } from '~/locale';
import { getAccessLevelLabel } from '~/packages_and_registries/settings/project/utils';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';

import * as Sentry from '~/sentry/sentry_browser_wrapper';

const MAX_LIMIT = 5;
const I18N_MINIMUM_ACCESS_LEVEL_TO_PUSH = s__('ContainerRegistry|Minimum access level to push');
const I18N_MINIMUM_ACCESS_LEVEL_TO_DELETE = s__('ContainerRegistry|Minimum access level to delete');

export default {
  components: {
    ContainerProtectionTagRuleForm,
    CrudComponent,
    GlAlert,
    GlBadge,
    GlButton,
    GlDrawer,
    GlLoadingIcon,
    GlModal,
    GlSkeletonLoader,
    GlSprintf,
    GlTable,
  },
  directives: {
    GlModal: GlModalDirective,
    GlTooltip: GlTooltipDirective,
  },
  inject: ['projectPath'],
  apollo: {
    protectionRulesQueryPayload: {
      query: getContainerProtectionTagRulesQuery,
      context: {
        batchKey: 'ContainerRegistryProjectSettings',
      },
      variables() {
        return {
          projectPath: this.projectPath,
          ...this.protectionRulesQueryPaginationParams,
        };
      },
      update(data) {
        return data.project?.containerProtectionTagRules ?? this.protectionRulesQueryPayload;
      },
      error(e) {
        this.alertErrorMessage = e.message;
      },
      result() {
        this.initialLoading = false;
      },
    },
  },
  data() {
    return {
      alertErrorMessage: '',
      initialLoading: true,
      protectionRuleMutationInProgress: false,
      protectionRuleMutationItem: null,
      protectionRulesQueryPayload: { nodes: [], pageInfo: {} },
      protectionRulesQueryPaginationParams: { first: MAX_LIMIT },
      showDrawer: false,
      showModal: false,
    };
  },
  computed: {
    containsTableItems() {
      return this.tagProtectionRulesCount > 0;
    },
    description() {
      return s__(
        'ContainerRegistry|When a container image tag is protected, only certain user roles can create, update, and delete the protected tag, which helps to prevent unauthorized changes. You can add up to 5 protection rules per project.',
      );
    },
    drawerTitle() {
      return this.protectionRuleMutationItem
        ? s__('ContainerRegistry|Edit protection rule')
        : s__('ContainerRegistry|Add protection rule');
    },
    getDrawerHeaderHeight() {
      return getContentWrapperHeight();
    },
    isLoadingProtectionRules() {
      return this.$apollo.queries.protectionRulesQueryPayload.loading;
    },
    protectionRulesQueryResult() {
      return this.protectionRulesQueryPayload.nodes;
    },
    rulesLimitReached() {
      return this.tagProtectionRulesCount === MAX_LIMIT;
    },
    mutationItemTagNamePattern() {
      return this.protectionRuleMutationItem?.tagNamePattern ?? '';
    },
    showTableLoading() {
      return this.protectionRuleMutationInProgress || this.isLoadingProtectionRules;
    },
    tableItems() {
      return this.protectionRulesQueryResult.map((protectionRule) => {
        return {
          id: protectionRule.id,
          minimumAccessLevelForPush: protectionRule.minimumAccessLevelForPush,
          minimumAccessLevelForDelete: protectionRule.minimumAccessLevelForDelete,
          tagNamePattern: protectionRule.tagNamePattern,
          immutable: protectionRule.immutable,
          userPermissions: protectionRule.userPermissions,
        };
      });
    },
    tagProtectionRulesCount() {
      return this.protectionRulesQueryResult.length;
    },
    toggleText() {
      if (this.initialLoading || this.rulesLimitReached) {
        return undefined;
      }
      return s__('ContainerRegistry|Add protection rule');
    },
    toastMessage() {
      return this.protectionRuleMutationItem
        ? s__('ContainerRegistry|Container protection rule updated.')
        : s__('ContainerRegistry|Container protection rule created.');
    },
  },
  methods: {
    clearAlertMessage() {
      this.alertErrorMessage = '';
    },
    closeDrawer() {
      this.showDrawer = false;
    },
    async deleteProtectionRule(protectionRule) {
      this.clearAlertMessage();

      this.protectionRuleMutationInProgress = true;

      try {
        const { data } = await this.$apollo.mutate({
          mutation: deleteContainerProtectionTagRuleMutation,
          variables: { input: { id: protectionRule.id } },
        });
        const [errorMessage] = data?.deleteContainerProtectionTagRule?.errors ?? [];
        if (errorMessage) {
          this.alertErrorMessage = errorMessage;
          return;
        }
        this.refetchProtectionRules();
        this.$toast.show(s__('ContainerRegistry|Container protection rule deleted.'));
      } catch (error) {
        this.alertErrorMessage = error.message;
        Sentry.captureException(error);
      } finally {
        this.resetProtectionRuleMutation();
      }
    },
    handleSubmit() {
      this.$toast.show(this.toastMessage);
      this.closeDrawer();
      this.refetchProtectionRules();
    },
    isEditable({ immutable }) {
      return !immutable;
    },
    openEditFormDrawer(item) {
      this.protectionRuleMutationItem = item;
      this.showDrawer = true;
    },
    openNewFormDrawer() {
      this.protectionRuleMutationItem = null;
      this.showDrawer = true;
    },
    refetchProtectionRules() {
      this.$apollo.queries.protectionRulesQueryPayload.refetch();
    },
    resetProtectionRuleMutation() {
      this.protectionRuleMutationItem = null;
      this.protectionRuleMutationInProgress = false;
    },
    showDeletionConfirmModal(protectionRule) {
      this.protectionRuleMutationItem = protectionRule;
      this.showModal = true;
    },
  },
  fields: [
    {
      key: 'tagNamePattern',
      label: s__('ContainerRegistry|Tag pattern'),
      tdClass: '!gl-align-middle',
    },
    {
      key: 'minimumAccessLevelForPush',
      label: I18N_MINIMUM_ACCESS_LEVEL_TO_PUSH,
      tdClass: '!gl-align-middle',
    },
    {
      key: 'minimumAccessLevelForDelete',
      label: I18N_MINIMUM_ACCESS_LEVEL_TO_DELETE,
      tdClass: '!gl-align-middle',
    },
    {
      key: 'rowActions',
      label: __('Actions'),
      thAlignRight: true,
      tdClass: '!gl-align-middle gl-text-right',
    },
  ],
  i18n: {
    deleteIconButton: __('Delete'),
    editIconButton: __('Edit'),
    title: s__('ContainerRegistry|Protected container image tags'),
    deletionConfirmModal: {
      title: s__('ContainerRegistry|Delete protection rule'),
      description: s__(
        'ContainerRegistry|Are you sure you want to delete the protected container tags rule %{tagNamePattern}?',
      ),
    },
  },
  getAccessLevelLabel,
  MAX_LIMIT,
  modal: { id: 'delete-protection-tag-rule-confirmation-modal' },
  modalActionPrimary: {
    text: s__('ContainerRegistry|Delete rule'),
    attributes: {
      variant: 'danger',
    },
  },
  modalActionCancel: {
    text: __('Cancel'),
  },
  DRAWER_Z_INDEX,
};
</script>

<template>
  <crud-component
    :collapsed="false"
    :title="$options.i18n.title"
    :description="description"
    :toggle-text="toggleText"
    data-testid="project-container-protection-tag-rules-settings"
    @showForm="openNewFormDrawer"
  >
    <template #description>
      <slot name="description"></slot>
    </template>

    <template v-if="containsTableItems" #count>
      <gl-badge>
        <gl-sprintf :message="s__('ContainerRegistry|%{count} of %{max}')">
          <template #count>
            {{ tagProtectionRulesCount }}
          </template>
          <template #max>
            {{ $options.MAX_LIMIT }}
          </template>
        </gl-sprintf>
      </gl-badge>
    </template>

    <template #actions>
      <span
        v-if="rulesLimitReached"
        class="gl-text-base gl-font-bold gl-leading-normal"
        data-testid="max-rules"
        >{{ s__('ContainerRegistry|Maximum number of rules reached.') }}</span
      >
      <div v-if="initialLoading">
        <gl-skeleton-loader :lines="1" :equal-width-lines="true" />
      </div>
    </template>

    <template #default>
      <gl-alert
        v-if="alertErrorMessage"
        class="gl-mb-5"
        variant="danger"
        @dismiss="clearAlertMessage"
      >
        {{ alertErrorMessage }}
      </gl-alert>

      <gl-loading-icon v-if="initialLoading" size="sm" class="gl-my-5" data-testid="loading-icon" />
      <gl-table
        v-else-if="containsTableItems"
        class="gl-border-t-1 gl-border-t-gray-100 gl-border-t-solid"
        :aria-label="$options.i18n.title"
        :busy="showTableLoading"
        :fields="$options.fields"
        :items="tableItems"
        stacked="md"
      >
        <template #table-busy>
          <gl-loading-icon size="sm" class="gl-my-5" data-testid="table-loading-icon" />
        </template>

        <template #cell(tagNamePattern)="{ item }">
          <span
            class="gl-flex gl-flex-nowrap gl-items-center gl-justify-end gl-gap-2 md:gl-justify-start"
          >
            <span data-testid="tag-name-pattern" class="gl-break-all">
              {{ item.tagNamePattern }}
            </span>
            <slot name="tag-badge" :item="item"></slot>
          </span>
        </template>

        <template #cell(minimumAccessLevelForPush)="{ item }">
          <span data-testid="minimum-access-level-push-value">
            {{ $options.getAccessLevelLabel(item.minimumAccessLevelForPush) }}
          </span>
        </template>

        <template #cell(minimumAccessLevelForDelete)="{ item }">
          <span data-testid="minimum-access-level-delete-value">
            {{ $options.getAccessLevelLabel(item.minimumAccessLevelForDelete) }}
          </span>
        </template>

        <template #cell(rowActions)="{ item }">
          <div class="gl-flex gl-justify-end">
            <gl-button
              v-if="isEditable(item)"
              v-gl-tooltip
              category="tertiary"
              icon="pencil"
              :title="$options.i18n.editIconButton"
              :aria-label="$options.i18n.editIconButton"
              @click="openEditFormDrawer(item)"
            />
            <gl-button
              v-if="item.userPermissions.destroyContainerRegistryProtectionTagRule"
              v-gl-tooltip
              v-gl-modal="$options.modal.id"
              category="tertiary"
              icon="remove"
              :title="$options.i18n.deleteIconButton"
              :aria-label="$options.i18n.deleteIconButton"
              @click="showDeletionConfirmModal(item)"
            />
          </div>
        </template>
      </gl-table>
      <p v-else data-testid="empty-text" class="gl-text-subtle">
        {{ s__('ContainerRegistry|No container image tags are protected.') }}
      </p>

      <gl-drawer
        :z-index="$options.DRAWER_Z_INDEX"
        :header-height="getDrawerHeaderHeight"
        :open="showDrawer"
        @close="closeDrawer"
      >
        <template #title>
          <h2 class="gl-my-0 gl-text-size-h2 gl-leading-24">
            {{ drawerTitle }}
          </h2>
        </template>
        <template #default>
          <container-protection-tag-rule-form
            :rule="protectionRuleMutationItem"
            @cancel="closeDrawer"
            @submit="handleSubmit"
          />
        </template>
      </gl-drawer>

      <gl-modal
        v-model="showModal"
        :modal-id="$options.modal.id"
        size="sm"
        :title="$options.i18n.deletionConfirmModal.title"
        :action-primary="$options.modalActionPrimary"
        :action-cancel="$options.modalActionCancel"
        @primary="deleteProtectionRule(protectionRuleMutationItem)"
      >
        <p>
          <gl-sprintf :message="$options.i18n.deletionConfirmModal.description">
            <template #tagNamePattern>
              <strong>{{ mutationItemTagNamePattern }}</strong>
            </template>
          </gl-sprintf>
        </p>
      </gl-modal>
    </template>
  </crud-component>
</template>
