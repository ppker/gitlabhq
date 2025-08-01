<script>
import {
  GlAvatarLabeled,
  GlButton,
  GlLink,
  GlTab,
  GlTabs,
  GlTableLite,
  GlTooltipDirective,
} from '@gitlab/ui';
import { isEmpty, maxBy, range } from 'lodash';
import { __, s__, sprintf } from '~/locale';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_PACKAGES_PACKAGE } from '~/graphql_shared/constants';

export default {
  name: 'CandidateDetail',
  components: {
    GlAvatarLabeled,
    GlButton,
    GlLink,
    GlTab,
    GlTabs,
    GlTableLite,
    PackageFiles: () =>
      import('~/packages_and_registries/package_registry/components/details/package_files.vue'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    candidate: {
      type: Object,
      required: true,
    },
  },
  computed: {
    info() {
      return this.candidate.info;
    },
    projectPath() {
      return this.candidate.projectPath;
    },
    packageType() {
      return 'ml_model';
    },
    packageId() {
      if (!this.info?.pathToArtifact) return null;
      return convertToGraphQLId(
        TYPENAME_PACKAGES_PACKAGE,
        this.info.pathToArtifact.split('/packages/')[1],
      );
    },
    ciJob() {
      return this.info.ciJob;
    },
    hasParameters() {
      return !isEmpty(this.candidate.params);
    },
    hasMetrics() {
      return !isEmpty(this.candidate.metrics);
    },
    metricsTableFields() {
      const maxMetric = maxBy(this.candidate.metrics, 'step');
      const maxStep = maxMetric ? maxMetric.step : 0;
      const rowClass = '!gl-p-3';

      const cssClasses = { thClass: rowClass, tdClass: rowClass };

      const fields = range(maxStep + 1).map((step) => ({
        key: step.toString(),
        label: sprintf(s__('MlExperimentTracking|Step %{step}'), { step }),
        ...cssClasses,
      }));

      return [{ key: 'name', label: s__('MlExperimentTracking|Metric'), ...cssClasses }, ...fields];
    },
    metricsTableItems() {
      const items = {};
      this.candidate.metrics.forEach((metric) => {
        const metricRow = items[metric.name] || { name: metric.name };
        metricRow[metric.step] = metric.value;
        items[metric.name] = metricRow;
      });

      return Object.values(items);
    },
    parameterTableItems() {
      return this.candidate.params.map((param) => ({ name: param.name, value: param.value }));
    },
    parameterTableFields() {
      return [
        { key: 'name', label: __('Name') },
        { key: 'value', label: __('Value') },
      ];
    },
  },
  methods: {
    copyMlflowId() {
      navigator.clipboard.writeText(this.info.eid);
    },
  },
  i18n: {
    detailsLabel: s__('MlExperimentTracking|Details & Metadata'),
    artifactsLabel: s__('MlExperimentTracking|Artifacts'),
    mlflowIdLabel: s__('MlExperimentTracking|MLflow run ID'),
    ciSectionLabel: s__('MlExperimentTracking|CI Info'),
    jobLabel: __('Job'),
    ciUserLabel: s__('MlExperimentTracking|Triggered by'),
    ciMrLabel: __('Merge request'),
    parametersLabel: s__('MlExperimentTracking|Parameters'),
    performanceLabel: s__('MlExperimentTracking|Performance'),
    noParametersMessage: s__('MlExperimentTracking|No logged parameters'),
    noMetricsMessage: s__('MlExperimentTracking|No logged metrics'),
    noCiMessage: s__('MlExperimentTracking|Run not linked to a CI build'),
    noArtifactsMessage: s__('MlExperimentTracking|No logged artifacts.'),
    copyMessage: __('Copy MLflow run ID'),
  },
};
</script>

<template>
  <div>
    <gl-tabs class="gl-mt-5">
      <gl-tab :title="$options.i18n.detailsLabel" class="gl-pt-3" data-testid="details">
        <section>
          <label class="gl-font-bold">{{ $options.i18n.mlflowIdLabel }}</label>
          <div
            class="gl-m-0 gl-w-fit gl-rounded-base gl-border-1 gl-border-solid gl-border-gray-500"
          >
            <span class="gl-pl-4 gl-pr-1" data-testid="mlflow-run-id">
              {{ info.eid }}
            </span>
            <gl-button
              v-gl-tooltip
              variant="default"
              category="tertiary"
              size="medium"
              :aria-label="$options.i18n.copyMessage"
              :title="$options.i18n.copyMessage"
              icon="copy-to-clipboard"
              @click="copyMlflowId"
            />
          </div>
          <div
            v-for="item in candidate.metadata"
            :key="item.name"
            class="gl-mt-3"
            data-testid="metadata"
          >
            <h5 class="gl-font-bold">{{ item.name }}</h5>
            <p>{{ item.value }}</p>
          </div>
        </section>
        <section class="gl-pt-3" data-testid="parameters">
          <h4>{{ $options.i18n.parametersLabel }}</h4>
          <gl-table-lite
            v-if="hasParameters"
            :items="parameterTableItems"
            :fields="parameterTableFields"
            class="gl-w-100"
            hover
            data-testid="parameters-table"
          />
          <div v-else class="gl-text-subtle">{{ $options.i18n.noParametersMessage }}</div>
        </section>
        <section data-testid="ci">
          <h4>{{ $options.i18n.ciSectionLabel }}</h4>
          <div v-if="ciJob" class="gl-pt-3">
            <div>
              <h5 class="gl-font-bold">{{ $options.i18n.jobLabel }}</h5>
              <gl-link :href="ciJob.path" data-testid="ci-job-path">
                {{ ciJob.name }}
              </gl-link>
            </div>
            <div v-if="ciJob.user" class="gl-pt-3">
              <h5 class="gl-font-bold">{{ $options.i18n.ciUserLabel }}</h5>
              <gl-avatar-labeled label="" :size="24" :src="ciJob.user.avatar">
                <gl-link :href="ciJob.user.path">
                  {{ ciJob.user.name }}
                </gl-link>
              </gl-avatar-labeled>
            </div>
            <div v-if="ciJob.mergeRequest" class="gl-pt-3">
              <h5 class="gl-font-bold">{{ $options.i18n.ciMrLabel }}</h5>
              <gl-link :href="ciJob.mergeRequest.path">
                !{{ ciJob.mergeRequest.iid }} {{ ciJob.mergeRequest.title }}
              </gl-link>
            </div>
          </div>
          <div v-else class="gl-text-subtle">{{ $options.i18n.noCiMessage }}</div>
        </section>
      </gl-tab>
      <gl-tab :title="$options.i18n.artifactsLabel" class="gl-pt-3" data-testid="artifacts">
        <package-files
          v-if="info.pathToArtifact"
          :project-path="projectPath"
          :package-type="packageType"
          :package-id="packageId"
        />
        <div v-else class="gl-text-subtle">{{ $options.i18n.noArtifactsMessage }}</div>
      </gl-tab>
      <gl-tab :title="$options.i18n.performanceLabel" class="gl-pt-3" data-testid="metrics">
        <div v-if="hasMetrics" class="gl-overflow-x-auto">
          <gl-table-lite
            :items="metricsTableItems"
            :fields="metricsTableFields"
            class="gl-w-100"
            hover
            data-testid="metrics-table"
          />
        </div>
        <div v-else class="gl-text-subtle">{{ $options.i18n.noMetricsMessage }}</div>
      </gl-tab>
    </gl-tabs>
  </div>
</template>
