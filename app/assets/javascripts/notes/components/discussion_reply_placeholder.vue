<script>
import { GlFormInput } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'ReplyPlaceholder',
  components: {
    GlFormInput,
  },
  props: {
    placeholderText: {
      type: String,
      required: false,
      default: __('Reply…'),
    },
    labelText: {
      type: String,
      required: false,
      default: __('Reply to comment'),
    },
  },
};
</script>

<template>
  <gl-form-input
    class="reply-placeholder-input-field"
    data-testid="discussion-reply-tab"
    :placeholder="placeholderText"
    :aria-label="labelText"
    @focus="$emit('focus')"
  />
</template>
