<script>
import { GlLink, GlSprintf, GlIcon } from '@gitlab/ui';
import { joinPaths } from '~/lib/utils/url_utility';

export default {
  components: {
    GlLink,
    GlSprintf,
    GlIcon,
  },
  props: {
    group: {
      type: Object,
      required: true,
    },
  },
  computed: {
    fullLastImportPath() {
      return this.group.lastImportTarget
        ? `${this.group.lastImportTarget.targetNamespace}/${this.group.lastImportTarget.newName}`
        : null;
    },
    absoluteLastImportPath() {
      return joinPaths(gon.relative_url_root || '/', this.fullLastImportPath);
    },
  },
};
</script>

<template>
  <div>
    <gl-link :href="group.webUrl" target="_blank">
      {{ group.fullPath }}&nbsp;<gl-icon name="external-link" class="gl-fill-icon-link" />
    </gl-link>
    <div v-if="group.flags.isFinished && fullLastImportPath" class="gl-text-sm gl-text-subtle">
      <gl-sprintf :message="s__('BulkImport|Last imported to %{link}')">
        <template #link>
          <gl-link :href="absoluteLastImportPath" class="gl-text-sm" target="_blank">{{
            fullLastImportPath
          }}</gl-link>
        </template>
      </gl-sprintf>
    </div>
  </div>
</template>
