<script>
import { GlLoadingIcon, GlSprintf, GlLink } from '@gitlab/ui';
import { backOff } from '~/lib/utils/common_utils';
import { HTTP_STATUS_NO_CONTENT } from '~/lib/utils/http_status';
import { bytesToMiB } from '~/lib/utils/number_utils';
import { s__ } from '~/locale';
import MemoryGraph from '~/vue_merge_request_widget/components/memory_graph.vue';
import MRWidgetService from '../../services/mr_widget_service';

export default {
  name: 'MemoryUsage',
  components: {
    MemoryGraph,
    GlLoadingIcon,
    GlSprintf,
    GlLink,
  },
  props: {
    metricsUrl: {
      type: String,
      required: true,
    },
    metricsMonitoringUrl: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      memoryFrom: 0,
      memoryTo: 0,
      memoryMetrics: [],
      deploymentTime: 0,
      hasMetrics: false,
      loadFailed: false,
      loadingMetrics: true,
      backOffRequestCounter: 0,
    };
  },
  computed: {
    shouldShowLoading() {
      return this.loadingMetrics && !this.hasMetrics && !this.loadFailed;
    },
    shouldShowMemoryGraph() {
      return !this.loadingMetrics && this.hasMetrics && !this.loadFailed;
    },
    shouldShowLoadFailure() {
      return !this.loadingMetrics && !this.hasMetrics && this.loadFailed;
    },
    shouldShowMetricsUnavailable() {
      return !this.loadingMetrics && !this.hasMetrics && !this.loadFailed;
    },
    memoryChangeMessage() {
      const memoryTo = Number(this.memoryTo);
      const memoryFrom = Number(this.memoryFrom);

      if (memoryTo > memoryFrom) {
        return s__(
          'mrWidget|%{metricsLinkStart} Memory %{metricsLinkEnd} usage %{emphasisStart} increased %{emphasisEnd} from %{memoryFrom}MB to %{memoryTo}MB',
        );
      }
      if (memoryTo < memoryFrom) {
        return s__(
          'mrWidget|%{metricsLinkStart} Memory %{metricsLinkEnd} usage %{emphasisStart} decreased %{emphasisEnd} from %{memoryFrom}MB to %{memoryTo}MB',
        );
      }

      return s__(
        'mrWidget|%{metricsLinkStart} Memory %{metricsLinkEnd} usage is %{emphasisStart} unchanged %{emphasisEnd} at %{memoryFrom}MB',
      );
    },
  },
  mounted() {
    this.loadingMetrics = true;
    this.loadMetrics();
  },
  methods: {
    getMegabytes(bytesString) {
      const valueInBytes = Number(bytesString).toFixed(2);
      return bytesToMiB(valueInBytes).toFixed(2);
    },
    computeGraphData(metrics, deploymentTime) {
      this.loadingMetrics = false;
      const {
        memory_before: memoryBefore,
        memory_after: memoryAfter,
        memory_values: memoryValues,
      } = metrics;

      // Both `memory_before` and `memory_after` objects
      // have peculiar structure where accessing only a specific
      // index yeilds correct value that we can use to show memory delta.
      if (memoryBefore.length > 0) {
        this.memoryFrom = this.getMegabytes(memoryBefore[0].value[1]);
      }

      if (memoryAfter.length > 0) {
        this.memoryTo = this.getMegabytes(memoryAfter[0].value[1]);
      }

      if (memoryValues.length > 0) {
        this.hasMetrics = true;
        this.memoryMetrics = memoryValues[0].values;
        this.deploymentTime = deploymentTime;
      }
    },
    loadMetrics() {
      backOff((next, stop) => {
        MRWidgetService.fetchMetrics(this.metricsUrl)
          .then((res) => {
            if (res.status === HTTP_STATUS_NO_CONTENT) {
              this.backOffRequestCounter += 1;
              /* eslint-disable no-unused-expressions */
              this.backOffRequestCounter < 3 ? next() : stop(res);
            } else {
              stop(res);
            }
          })
          .catch(stop);
      })
        .then((res) => {
          if (res.status === HTTP_STATUS_NO_CONTENT) {
            return res;
          }

          return res.data;
        })
        .then((data) => {
          this.computeGraphData(data.metrics, data.deployment_time);
          return data;
        })
        .catch(() => {
          this.loadFailed = true;
          this.loadingMetrics = false;
        });
    },
  },
};
</script>

<template>
  <div class="mr-info-list clearfix mr-memory-usage js-mr-memory-usage">
    <p v-if="shouldShowLoading" class="usage-info js-usage-info usage-info-loading">
      <gl-loading-icon size="sm" class="usage-info-load-spinner" />{{
        s__('mrWidget|Loading deployment statistics')
      }}
    </p>
    <p v-if="shouldShowMemoryGraph" class="usage-info js-usage-info">
      <gl-sprintf :message="memoryChangeMessage">
        <template #metricsLink="{ content }">
          <gl-link :href="metricsMonitoringUrl">{{ content }}</gl-link>
        </template>
        <template #emphasis="{ content }">
          <strong>{{ content }}</strong>
        </template>
        <template #memoryFrom>{{ memoryFrom }}</template>
        <template #memoryTo>{{ memoryTo }}</template>
      </gl-sprintf>
    </p>

    <p v-if="shouldShowLoadFailure" class="usage-info js-usage-info usage-info-failed">
      {{ s__('mrWidget|Failed to load deployment statistics') }}
    </p>
    <p v-if="shouldShowMetricsUnavailable" class="usage-info js-usage-info usage-info-unavailable">
      {{ s__('mrWidget|Deployment statistics are not available currently') }}
    </p>
    <memory-graph v-if="shouldShowMemoryGraph" :metrics="memoryMetrics" :height="25" :width="110" />
  </div>
</template>
