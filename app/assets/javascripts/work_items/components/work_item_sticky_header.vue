<script>
import { GlIntersectionObserver, GlButton, GlLink } from '@gitlab/ui';
import HiddenBadge from '~/issuable/components/hidden_badge.vue';
import LockedBadge from '~/issuable/components/locked_badge.vue';
import { WORKSPACE_PROJECT } from '~/issues/constants';
import ConfidentialityBadge from '~/vue_shared/components/confidentiality_badge.vue';
import ImportedBadge from '~/vue_shared/components/imported_badge.vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { findNotesWidget } from '../utils';
import TodosToggle from './shared/todos_toggle.vue';
import WorkItemStateBadge from './work_item_state_badge.vue';
import WorkItemNotificationsWidget from './work_item_notifications_widget.vue';

export default {
  components: {
    HiddenBadge,
    ImportedBadge,
    LockedBadge,
    GlIntersectionObserver,
    TodosToggle,
    ConfidentialityBadge,
    WorkItemStateBadge,
    WorkItemNotificationsWidget,
    GlButton,
    GlLink,
  },
  mixins: [glFeatureFlagMixin()],
  props: {
    workItem: {
      type: Object,
      required: true,
    },
    isStickyHeaderShowing: {
      type: Boolean,
      required: true,
    },
    showWorkItemCurrentUserTodos: {
      type: Boolean,
      required: false,
      default: false,
    },
    currentUserTodos: {
      type: Array,
      required: false,
      default: () => [],
    },
    isDrawer: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    canUpdate() {
      return this.workItem.userPermissions?.updateWorkItem;
    },
    isDiscussionLocked() {
      return findNotesWidget(this.workItem)?.discussionLocked;
    },
    workItemType() {
      return this.workItem.workItemType?.name;
    },
    workItemState() {
      return this.workItem.state;
    },
    newTodoAndNotificationsEnabled() {
      return this.glFeatures.notificationsTodosButtons;
    },
  },
  WORKSPACE_PROJECT,
};
</script>

<template>
  <gl-intersection-observer
    @appear="$emit('hideStickyHeader')"
    @disappear="$emit('showStickyHeader')"
  >
    <transition name="issuable-header-slide">
      <div
        v-if="isStickyHeaderShowing"
        class="issue-sticky-header gl-border-b gl-z-3 gl-bg-default gl-py-2"
        :class="{ 'gl-absolute gl-left-0 gl-top-10': isDrawer, 'gl-fixed': !isDrawer }"
        data-testid="work-item-sticky-header"
      >
        <div
          class="work-item-sticky-header-text gl-mx-auto gl-flex gl-items-center gl-gap-3 gl-px-5 xl:gl-px-6"
        >
          <work-item-state-badge
            v-if="workItemState"
            :work-item-state="workItemState"
            :promoted-to-epic-url="workItem.promotedToEpicUrl"
            :duplicated-to-work-item-url="workItem.duplicatedToWorkItemUrl"
            :moved-to-work-item-url="workItem.movedToWorkItemUrl"
          />
          <confidentiality-badge
            v-if="workItem.confidential"
            :issuable-type="workItemType"
            :workspace-type="$options.WORKSPACE_PROJECT"
            hide-text-in-small-screens
          />
          <locked-badge v-if="isDiscussionLocked" :issuable-type="workItemType" />
          <hidden-badge v-if="workItem.hidden" />
          <imported-badge v-if="workItem.imported" />
          <gl-link
            class="gl-mr-auto gl-block gl-truncate gl-pr-3 gl-font-bold gl-text-strong"
            href="#top"
            :title="workItem.title"
          >
            {{ workItem.title }}
          </gl-link>
          <gl-button
            v-if="canUpdate"
            category="secondary"
            data-testid="work-item-edit-button-sticky"
            class="shortcut-edit-wi-description gl-shrink-0"
            @click="$emit('toggleEditMode')"
          >
            {{ __('Edit') }}
          </gl-button>
          <todos-toggle
            v-if="showWorkItemCurrentUserTodos"
            :item-id="workItem.id"
            :current-user-todos="currentUserTodos"
            todos-button-type="secondary"
            @todosUpdated="$emit('todosUpdated', $event)"
            @error="updateError = $event"
          />
          <work-item-notifications-widget
            v-if="newTodoAndNotificationsEnabled"
            :work-item-id="workItem.id"
            @error="$emit('error')"
          />
          <slot name="actions"></slot>
        </div>
      </div>
    </transition>
  </gl-intersection-observer>
</template>
