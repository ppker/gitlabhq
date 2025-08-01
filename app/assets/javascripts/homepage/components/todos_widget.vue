<script>
import { computed } from 'vue';
import { GlCollapsibleListbox, GlTooltipDirective, GlSkeletonLoader } from '@gitlab/ui';
import emptyTodosAllDoneSvg from '@gitlab/svgs/dist/illustrations/status/status-success-sm.svg';
import emptyTodosFilteredSvg from '@gitlab/svgs/dist/illustrations/search-sm.svg';
import { s__ } from '~/locale';
import { InternalEvents } from '~/tracking';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import {
  TABS_INDICES,
  TODO_ACTION_TYPE_BUILD_FAILED,
  TODO_ACTION_TYPE_DIRECTLY_ADDRESSED,
  TODO_ACTION_TYPE_ASSIGNED,
  TODO_ACTION_TYPE_MENTIONED,
  TODO_ACTION_TYPE_REVIEW_REQUESTED,
  TODO_ACTION_TYPE_UNMERGEABLE,
} from '~/todos/constants';
import TodoItem from '~/todos/components/todo_item.vue';
import getTodosQuery from '~/todos/components/queries/get_todos.query.graphql';
import {
  EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE,
  TRACKING_LABEL_TODO_ITEMS,
  TRACKING_PROPERTY_ALL_TODOS,
} from '../tracking_constants';
import VisibilityChangeDetector from './visibility_change_detector.vue';

const N_TODOS = 5;

const FILTER_OPTIONS = [
  {
    value: null,
    text: s__('Todos|All'),
  },
  {
    value: TODO_ACTION_TYPE_ASSIGNED,
    text: s__('Todos|Assigned'),
  },
  {
    value: `${TODO_ACTION_TYPE_MENTIONED};${TODO_ACTION_TYPE_DIRECTLY_ADDRESSED}`,
    text: s__('Todos|Mentioned'),
  },
  {
    value: TODO_ACTION_TYPE_BUILD_FAILED,
    text: s__('Todos|Build failed'),
  },
  {
    value: TODO_ACTION_TYPE_UNMERGEABLE,
    text: s__('Todos|Unmergeable'),
  },
  {
    value: TODO_ACTION_TYPE_REVIEW_REQUESTED,
    text: s__('Todos|Review requested'),
  },
];

export default {
  components: { TodoItem, GlCollapsibleListbox, GlSkeletonLoader, VisibilityChangeDetector },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [InternalEvents.mixin()],
  provide() {
    return {
      currentTab: TABS_INDICES.pending,
      currentTime: new Date(),
      currentUserId: computed(() => this.currentUserId),
    };
  },
  data() {
    return {
      currentUserId: null,
      filter: null,
      todos: [],
      showLoading: true,
      hasError: false,
    };
  },
  apollo: {
    todos: {
      query: getTodosQuery,
      variables() {
        return {
          first: N_TODOS,
          state: ['pending'],
          action: this.filter ? this.filter.split(';') : null,
        };
      },
      update({ currentUser: { id, todos: { nodes = [] } } = {} }) {
        this.currentUserId = id;
        this.showLoading = false;

        return nodes;
      },
      error(error) {
        Sentry.captureException(error);
        this.showLoading = false;
        this.hasError = true;
      },
    },
  },
  methods: {
    reload() {
      this.showLoading = true;
      this.hasError = false;
      this.$apollo.queries.todos.refetch();
    },
    handleViewAllClick() {
      this.trackEvent(EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE, {
        label: TRACKING_LABEL_TODO_ITEMS,
        property: TRACKING_PROPERTY_ALL_TODOS,
      });
    },
  },

  emptyTodosAllDoneSvg,
  emptyTodosFilteredSvg,
  FILTER_OPTIONS,
};
</script>

<template>
  <visibility-change-detector @visible="reload">
    <div class="gl-flex gl-items-center gl-justify-between gl-gap-2">
      <h2 class="gl-heading-4 gl-my-4 gl-grow">{{ __('To-do items') }}</h2>

      <gl-collapsible-listbox v-if="!hasError" v-model="filter" :items="$options.FILTER_OPTIONS" />
    </div>

    <p v-if="hasError">
      {{
        s__(
          'HomePageTodosWidget|Your to-do items are not available. Please refresh the page to try again.',
        )
      }}
    </p>
    <div v-else class="gl-rounded-lg gl-bg-subtle">
      <div v-if="showLoading && $apollo.queries.todos.loading" class="gl-p-4">
        <gl-skeleton-loader v-for="i in 5" :key="i" :width="200" :height="10">
          <rect x="0" y="0" width="16" height="8" rx="2" ry="2" />
          <rect x="24" y="0" width="174" height="8" rx="2" ry="2" />
          <rect x="182" y="0" width="16" height="8" rx="2" ry="2" />
        </gl-skeleton-loader>
      </div>

      <div
        v-else-if="!$apollo.queries.todos.loading && !todos.length && !filter"
        class="gl-flex gl-items-center gl-gap-5 gl-rounded-lg gl-bg-subtle gl-p-4"
      >
        <img class="gl-h-11" aria-hidden="true" :src="$options.emptyTodosAllDoneSvg" />
        <span>
          <strong>{{ __('Good job!') }}</strong>
          {{ __('All your to-do items are done.') }}
        </span>
      </div>
      <div
        v-else-if="!$apollo.queries.todos.loading && !todos.length && filter"
        class="gl-flex gl-items-center gl-gap-5 gl-rounded-lg gl-bg-subtle gl-p-4"
      >
        <img class="gl-h-11" aria-hidden="true" :src="$options.emptyTodosFilteredSvg" />
        <span>{{ __('Sorry, your filter produced no results') }}</span>
      </div>
      <ol v-else class="gl-m-0 gl-list-none gl-p-0">
        <todo-item
          v-for="todo in todos"
          :key="todo.id"
          class="first:gl-rounded-t-lg hover:!gl-bg-strong"
          :todo="todo"
          @change="$apollo.queries.todos.refetch()"
        />
      </ol>

      <div class="gl-px-5 gl-py-3">
        <a href="/dashboard/todos" @click="handleViewAllClick">{{ __('All to-do items') }}</a>
      </div>
    </div>
  </visibility-change-detector>
</template>
