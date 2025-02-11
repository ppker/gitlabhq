<script>
import { GlButton, GlLoadingIcon } from '@gitlab/ui';

export default {
  components: { GlButton, GlLoadingIcon },
  inject: ['canUpdate'],
  props: {
    title: {
      type: String,
      required: false,
      default: '',
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    toggleHeader: {
      type: Boolean,
      required: false,
      default: false,
    },
    handleOffClick: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  data() {
    return {
      edit: false,
    };
  },
  computed: {
    showHeader() {
      if (!this.toggleHeader) {
        return true;
      }

      return !this.edit;
    },
  },
  destroyed() {
    window.removeEventListener('click', this.collapseWhenOffClick);
  },
  methods: {
    collapseWhenOffClick({ target }) {
      if (!this.$el.contains(target)) {
        this.$emit('off-click');
        if (this.handleOffClick) {
          this.collapse();
        }
      }
    },
    expand() {
      if (this.edit) {
        return;
      }

      this.edit = true;
      this.$emit('open');
      window.addEventListener('click', this.collapseWhenOffClick);
    },
    collapse({ emitEvent = true } = {}) {
      if (!this.edit) {
        return;
      }

      this.edit = false;
      if (emitEvent) {
        this.$emit('close');
      }
      window.removeEventListener('click', this.collapseWhenOffClick);
    },
    toggle({ emitEvent = true } = {}) {
      if (this.edit) {
        this.collapse({ emitEvent });
      } else {
        this.expand();
      }
    },
  },
};
</script>

<template>
  <div>
    <header v-show="showHeader" class="gl-mb-2 gl-flex gl-items-center gl-justify-between">
      <span class="gl-align-middle">
        <slot name="title">
          <span data-testid="title">{{ title }}</span>
        </slot>
        <gl-loading-icon v-if="loading" size="sm" inline class="gl-ml-2" />
      </span>
      <gl-button
        v-if="canUpdate"
        category="tertiary"
        size="small"
        class="js-sidebar-dropdown-toggle edit-link gl-ml-5"
        data-testid="edit-button"
        @click="toggle"
      >
        {{ __('Edit') }}
      </gl-button>
    </header>
    <div v-show="!edit" class="value gl-text-subtle" data-testid="collapsed-content">
      <slot name="collapsed">{{ __('None') }}</slot>
    </div>
    <div v-show="edit" data-testid="expanded-content">
      <slot :edit="edit"></slot>
    </div>
  </div>
</template>
