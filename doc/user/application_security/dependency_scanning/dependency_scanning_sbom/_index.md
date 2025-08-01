---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Dependency scanning by using SBOM
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/395692) in GitLab 17.1 and officially released in GitLab 17.3 with a flag named `dependency_scanning_using_sbom_reports`.
- [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/395692) in GitLab 17.5.
- Released [lockfile-based Dependency Scanning](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning/-/blob/main/README.md?ref_type=heads#supported-files) analyzer as an [Experiment](../../../../policy/development_stages_support.md#experiment) in GitLab 17.4.
- Released [Dependency Scanning CI/CD Component](https://gitlab.com/explore/catalog/components/dependency-scanning) version [`0.4.0`](https://gitlab.com/components/dependency-scanning/-/tags/0.4.0) in GitLab 17.5 with support for the [lockfile-based Dependency Scanning](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning/-/blob/main/README.md?ref_type=heads#supported-files) analyzer.
- [Enabled by default with the latest Dependency Scanning CI/CD templates](https://gitlab.com/gitlab-org/gitlab/-/issues/519597) for Cargo, Conda, Cocoapods, and Swift in GitLab 17.9.
- Feature flag `dependency_scanning_using_sbom_reports` removed in GitLab 17.10.

{{< /history >}}

Dependency scanning using CycloneDX SBOM analyzes your application's dependencies for known
vulnerabilities. All dependencies are scanned, [including transitive dependencies](../_index.md).

Dependency scanning is often considered part of Software Composition Analysis (SCA). SCA can contain
aspects of inspecting the items your code uses. These items typically include application and system
dependencies that are almost always imported from external sources, rather than sourced from items
you wrote yourself.

Dependency scanning can run in the development phase of your application's lifecycle. Every time a
pipeline produces an SBOM report, security findings are identified and compared between the source
and target branches. Findings and their severity are listed in the merge request, enabling you to
proactively address the risk to your application, before the code change is committed. Security
findings for reported SBOM components are also identified by
[Continuous Vulnerability Scanning](../../continuous_vulnerability_scanning/_index.md)
when new security advisories are published, independently from CI/CD pipelines.

GitLab offers both dependency scanning and [container scanning](../../container_scanning/_index.md) to
ensure coverage for all of these dependency types. To cover as much of your risk area as possible,
we encourage you to use all of our security scanners. For a comparison of these features, see
[Dependency Scanning compared to Container Scanning](../../comparison_dependency_and_container_scanning.md).

## Getting started

Enable the Dependency Scanning using SBOM feature with one of the following options:

- Use the `latest` Dependency Scanning CI/CD template `Dependency-Scanning.latest.gitlab-ci.yml` to enable a GitLab provided analyzer.
  - The (deprecated) Gemnasium analyzer is used by default.
  - To enable the new Dependency Scanning analyzer, set the CI/CD variable `DS_ENFORCE_NEW_ANALYZER` to `true`.
  - A [supported lock file, dependency graph](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning/#supported-files),
  or [trigger file](#trigger-files) must exist in the repository to create the `dependency-scanning` job in pipelines.
- Use the [Scan Execution Policies](../../policies/scan_execution_policies.md) with the `latest` template to enable a GitLab provided analyzer.
  - The (deprecated) Gemnasium analyzer is used by default.
  - To enable the new Dependency Scanning analyzer, set the CI/CD variable `DS_ENFORCE_NEW_ANALYZER` to `true`.
  - A [supported lock file, dependency graph](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning/#supported-files),
  or [trigger file](#trigger-files) must exist in the repository to create the `dependency-scanning` job in pipelines.
- Use the [Dependency Scanning CI/CD component](https://gitlab.com/explore/catalog/components/dependency-scanning) to enable the new Dependency Scanning analyzer.
- Provide your own CycloneDX SBOM document as [a CI/CD artifact report](../../../../ci/yaml/artifacts_reports.md#artifactsreportscyclonedx) from a successful pipeline.

You should use the new Dependency Scanning analyzer. For details, see [Enabling the analyzer](#enabling-the-analyzer).
If instead you use the (deprecated) Gemnasium analyzer, refer to the enablement instructions for the [legacy Dependency Scanning feature](../_index.md#getting-started).

### Enabling the analyzer

The Dependency Scanning analyzer produces a CycloneDX SBOM report compatible with GitLab. If your
application can't generate such a report, you can use the GitLab analyzer to produce one.

Share any feedback on the new Dependency Scanning analyzer in this [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/523458).

Prerequisites:

- A [supported lock file or dependency graph](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning/#supported-files)
  must exist in the repository or must be passed as an artifact to the `dependency-scanning` job.
- The component's [stage](https://gitlab.com/explore/catalog/components/dependency-scanning) is required in the `.gitlab-ci.yml` file.
- With self-managed runners you need a GitLab Runner with the
  [`docker`](https://docs.gitlab.com/runner/executors/docker.html) or
  [`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes.html) executor.
  - If you're using SaaS runners on GitLab.com, this is enabled by default.

To enable the analyzer, you must:

- Use either the `latest` Dependency Scanning CI/CD template `Dependency-Scanning.latest.gitlab-ci.yml`
and enforce the new Dependency Scanning analyzer by setting the CI/CD variable `DS_ENFORCE_NEW_ANALYZER` to `true`.

  ```yaml
  include:
    - template: Jobs/Dependency-Scanning.latest.gitlab-ci.yml

  variables:
    DS_ENFORCE_NEW_ANALYZER: 'true'
  ```

- Use the [Scan Execution Policies](../../policies/scan_execution_policies.md) with the `latest` template and enforce the new Dependency Scanning analyzer by setting the CI/CD variable `DS_ENFORCE_NEW_ANALYZER` to `true`.
- Use the [Dependency Scanning CI/CD component](https://gitlab.com/explore/catalog/components/dependency-scanning)

  ```yaml
  include:
    - component: $CI_SERVER_FQDN/components/dependency-scanning/main@0
  ```

#### Trigger files

Trigger files create a `dependency-scanning` CI/CD job when using the [latest Dependency Scanning CI template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Dependency-Scanning.latest.gitlab-ci.yml).
The analyzer does not scan these files.
Your project can be supported if you use a trigger file to [build](#language-specific-instructions) a [supported lock file](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning/#supported-files).

| Language | Files |
| -------- | ------- |
| C#/Visual Basic | `*.csproj`, `*.vbproj` |
| Java | `pom.xml` |
| Java/Kotlin | `build.gradle`, `build.gradle.kts` |
| Python | `requirements.pip`, `Pipfile`, `requires.txt`, `setup.py` |
| Scala | `build.sbt` |

#### Language-specific instructions

If your project doesn't have a supported lock file dependency graph committed to its
repository, you need to provide one.

The examples below show how to create a file that is supported by the GitLab analyzer for popular
languages and package managers.

##### Go

If your project provides only a `go.mod` file, the Dependency Scanning analyzer can still extract the list of components. However, [dependency path](../../dependency_list/_index.md#dependency-paths) information is not available. Additionally, you might encounter false positives if there are multiple versions of the same module.

To benefit from improved component detection and feature coverage, you should provide a `go.graph` file generated using the [`go mod graph` command](https://go.dev/ref/mod#go-mod-graph) from the Go toolchain.

The following example `.gitlab-ci.yml` demonstrates how to enable the CI/CD
component with [dependency path](../../dependency_list/_index.md#dependency-paths)
support on a Go project. The dependency graph is output as a job artifact in the `build`
stage, before dependency scanning runs.

```yaml
stages:
  - build
  - test

include:
  - component: $CI_SERVER_FQDN/components/dependency-scanning/main@0

go:build:
  stage: build
  image: "golang:latest"
  script:
    - "go mod tidy"
    - "go build ./..."
    - "go mod graph > go.graph"
  artifacts:
    when: on_success
    access: developer
    paths: ["**/go.graph"]

```

##### Gradle

For Gradle projects use either of the following methods to create a dependency graph.

- Nebula Gradle Dependency Lock Plugin
- Gradle's HtmlDependencyReportTask

###### Dependency Lock Plugin

This method gives information about dependencies which are direct.

To enable the CI/CD component on a Gradle project:

1. Edit the `build.gradle` or `build.gradle.kts` to use the
   [gradle-dependency-lock-plugin](https://github.com/nebula-plugins/gradle-dependency-lock-plugin/wiki/Usage#example) or use an init script.
1. Configure the `.gitlab-ci.yml` file to generate the `dependencies.lock` and `dependencies.direct.lock` artifacts, and pass them
   to the `dependency-scanning` job.

The following example demonstrates how to configure the component
for a Gradle project.

```yaml
stages:
  - build
  - test

image: gradle:8.0-jdk11

include:
  - component: $CI_SERVER_FQDN/components/dependency-scanning/main@0

generate nebula lockfile:
  # Running in the build stage ensures that the dependency-scanning job
  # receives the scannable artifacts.
  stage: build
  script:
    - |
      cat << EOF > nebula.gradle
      initscript {
          repositories {
            mavenCentral()
          }
          dependencies {
              classpath 'com.netflix.nebula:gradle-dependency-lock-plugin:12.7.1'
          }
      }

      allprojects {
          apply plugin: nebula.plugin.dependencylock.DependencyLockPlugin
      }
      EOF
      ./gradlew --init-script nebula.gradle -PdependencyLock.includeTransitives=true -PdependencyLock.lockFile=dependencies.lock generateLock saveLock
      ./gradlew --init-script nebula.gradle -PdependencyLock.includeTransitives=false -PdependencyLock.lockFile=dependencies.direct.lock generateLock saveLock
      # generateLock saves the lock file in the build/ directory of a project
      # and saveLock copies it into the root of a project. To avoid duplicates
      # and get an accurate location of the dependency, use find to remove the
      # lock files in the build/ directory only.
  after_script:
    - find . -path '*/build/dependencies*.lock' -print -delete
  # Collect all generated artifacts and pass them onto jobs in sequential stages.
  artifacts:
    paths:
      - '**/dependencies*.lock'
      - '**/dependencies*.lock'
```

###### HtmlDependencyReportTask

This method gives information about dependencies which are both transitive and direct.

The [HtmlDependencyReportTask](https://docs.gradle.org/current/dsl/org.gradle.api.reporting.dependencies.HtmlDependencyReportTask.html)
is an alternative way to get the list of dependencies for a Gradle project (tested with `gradle`
versions 4 through 8). To enable use of this method with dependency scanning the artifact from running the
`gradle htmlDependencyReport` task needs to be available.

```yaml
stages:
  - build
  - test

# Define the image that contains Java and Gradle
image: gradle:8.0-jdk11

include:
  - component: $CI_SERVER_FQDN/components/dependency-scanning/main@0

build:
  stage: build
  script:
    - gradle --init-script report.gradle htmlDependencyReport
  # The gradle task writes the dependency report as a javascript file under
  # build/reports/project/dependencies. Because the file has an un-standardized
  # name, the after_script finds and renames the file to
  # `gradle-html-dependency-report.js` copying it to the  same directory as
  # `build.gradle`
  after_script:
    - |
      reports_dir=build/reports/project/dependencies
      while IFS= read -r -d '' src; do
        dest="${src%%/$reports_dir/*}/gradle-html-dependency-report.js"
        cp $src $dest
      done < <(find . -type f -path "*/${reports_dir}/*.js" -not -path "*/${reports_dir}/js/*" -print0)
  # Pass html report artifact to subsequent dependency scanning stage.
  artifacts:
    paths:
      - "**/gradle-html-dependency-report.js"
```

The command above uses the `report.gradle` file and can be supplied through `--init-script` or its contents can be added to `build.gradle` directly:

```kotlin
allprojects {
    apply plugin: 'project-report'
}
```

{{< alert type="note" >}}

The dependency report may indicate that dependencies for some configurations `FAILED` to be
resolved. In this case dependency scanning logs a warning but does not fail the job. If you prefer
to have the pipeline fail if resolution failures are reported, add the following extra steps to the
`build` example above.

{{< /alert >}}

```shell
while IFS= read -r -d '' file; do
  grep --quiet -E '"resolvable":\s*"FAILED' $file && echo "Dependency report has dependencies with FAILED resolution status" && exit 1
done < <(find . -type f -path "*/gradle-html-dependency-report.js -print0)
```

##### Maven

The following example `.gitlab-ci.yml` demonstrates how to enable the CI/CD
component on a Maven project. The dependency graph is output as a job artifact
in the `build` stage, before dependency scanning runs.

Requirement: use at least version `3.7.0` of the maven-dependency-plugin.

```yaml
stages:
  - build
  - test

image: maven:3.9.9-eclipse-temurin-21

include:
  - component: $CI_SERVER_FQDN/components/dependency-scanning/main@0

build:
  # Running in the build stage ensures that the dependency-scanning job
  # receives the maven.graph.json artifacts.
  stage: build
  script:
    - mvn install
    - mvn org.apache.maven.plugins:maven-dependency-plugin:3.8.1:tree -DoutputType=json -DoutputFile=maven.graph.json
  # Collect all maven.graph.json artifacts and pass them onto jobs
  # in sequential stages.
  artifacts:
    paths:
      - "**/*.jar"
      - "**/maven.graph.json"
```

##### pip

If your project provides a `requirements.txt` lock file generated by the [pip-compile command line tool](https://pip-tools.readthedocs.io/en/latest/cli/pip-compile/),
the Dependency Scanning analyzer can extract the list of components and the dependency graph information,
which provides support for the [dependency path](../../dependency_list/_index.md#dependency-paths) feature.

Alternatively, your project can provide a `pipdeptree.json` dependency graph export generated by the [`pipdeptree --json` command line utility](https://pypi.org/project/pipdeptree/).

The following example `.gitlab-ci.yml` demonstrates how to enable the CI/CD
component with [dependency path](../../dependency_list/_index.md#dependency-paths)
support on a pip project. The `build` stage outputs the dependency graph as a job artifact
before dependency scanning runs.

```yaml
stages:
  - build
  - test

include:
  - component: $CI_SERVER_FQDN/components/dependency-scanning/main@0

build:
  stage: build
  image: "python:latest"
  script:
    - "pip install -r requirements.txt"
    - "pip install pipdeptree"
    - "pipdeptree --json > pipdeptree.json"
  artifacts:
    when: on_success
    access: developer
    paths: ["**/pipdeptree.json"]
```

Because of a [known issue](https://github.com/tox-dev/pipdeptree/issues/107), `pipdeptree` does not mark
[optional dependencies](https://setuptools.pypa.io/en/latest/userguide/dependency_management.html#optional-dependencies)
as dependencies of the parent package. As a result, Dependency Scanning marks them as direct dependencies of the project,
instead of as transitive dependencies.

##### Pipenv

If your project provides only a `Pipfile.lock` file, the Dependency Scanning analyzer can still extract the list of components. However, [dependency path](../../dependency_list/_index.md#dependency-paths) information is not available.

To benefit from improved feature coverage, you should provide a `pipenv.graph.json` file generated by the [`pipenv graph` command](https://pipenv.pypa.io/en/latest/cli.html#graph).

The following example `.gitlab-ci.yml` demonstrates how to enable the CI/CD
component with [dependency path](../../dependency_list/_index.md#dependency-paths)
support on a Pipenv project. The `build` stage outputs the dependency graph as a job artifact
before dependency scanning runs.

```yaml
stages:
  - build
  - test

include:
  - component: $CI_SERVER_FQDN/components/dependency-scanning/main@0

build:
  stage: build
  image: "python:3.12"
  script:
    - "pip install pipenv"
    - "pipenv install"
    - "pipenv graph --json-tree > pipenv.graph.json"
  artifacts:
    when: on_success
    access: developer
    paths: ["**/pipenv.graph.json"]
```

##### sbt

To enable the CI/CD component on an sbt project:

- Edit the `plugins.sbt` to use the
  [sbt-dependency-graph plugin](https://github.com/sbt/sbt-dependency-graph/blob/master/README.md#usage-instructions).

The following example `.gitlab-ci.yml` demonstrates how to enable the CI/CD
component with [dependency path](../../dependency_list/_index.md#dependency-paths)
support in an sbt project. The `build` stage outputs the dependency graph as a job artifact
before dependency scanning runs.

```yaml
stages:
  - build
  - test

include:
  - component: $CI_SERVER_FQDN/components/dependency-scanning/main@0

build:
  stage: build
  image: "sbtscala/scala-sbt:eclipse-temurin-17.0.13_11_1.10.7_3.6.3"
  script:
    - "sbt dependencyDot"
  artifacts:
    when: on_success
    access: developer
    paths: ["**/dependencies-compile.dot"]
```

## Understanding the results

The dependency scanning analyzer produces CycloneDX Software Bill of Materials (SBOM) for each supported
lock file or dependency graph export detected.

### CycloneDX Software Bill of Materials

The dependency scanning analyzer outputs a [CycloneDX](https://cyclonedx.org/) Software Bill of Materials (SBOM)
for each supported lock or dependency graph export it detects. The CycloneDX SBOMs are created as job artifacts.

The CycloneDX SBOMs are:

- Named `gl-sbom-<package-type>-<package-manager>.cdx.json`.
- Available as job artifacts of the dependency scanning job.
- Uploaded as `cyclonedx` reports.
- Saved in the same directory as the detected lock or dependency graph exports files.

For example, if your project has the following structure:

```plaintext
.
├── ruby-project/
│   └── Gemfile.lock
├── ruby-project-2/
│   └── Gemfile.lock
└── php-project/
    └── composer.lock
```

The following CycloneDX SBOMs are created as job artifacts:

```plaintext
.
├── ruby-project/
│   ├── Gemfile.lock
│   └── gl-sbom-gem-bundler.cdx.json
├── ruby-project-2/
│   ├── Gemfile.lock
│   └── gl-sbom-gem-bundler.cdx.json
└── php-project/
    ├── composer.lock
    └── gl-sbom-packagist-composer.cdx.json
```

### Merging multiple CycloneDX SBOMs

You can use a CI/CD job to merge the multiple CycloneDX SBOMs into a single SBOM.

{{< alert type="note" >}}

GitLab uses [CycloneDX Properties](https://cyclonedx.org/use-cases/#properties--name-value-store)
to store implementation-specific details in the metadata of each CycloneDX SBOM, such as the
location of dependency graph exports and lock files. If multiple CycloneDX SBOMs are merged together,
this information is removed from the resulting merged file.

{{< /alert >}}

For example, the following `.gitlab-ci.yml` extract demonstrates how the Cyclone SBOM files can be
merged, and the resulting file validated.

```yaml
stages:
  - test
  - merge-cyclonedx-sboms

include:
  - component: $CI_SERVER_FQDN/components/dependency-scanning/main@0

merge cyclonedx sboms:
  stage: merge-cyclonedx-sboms
  image:
    name: cyclonedx/cyclonedx-cli:0.27.1
    entrypoint: [""]
  script:
    - find . -name "gl-sbom-*.cdx.json" -exec cyclonedx merge --output-file gl-sbom-all.cdx.json --input-files "{}" +
    # optional: validate the merged sbom
    - cyclonedx validate --input-version v1_6 --input-file gl-sbom-all.cdx.json
  artifacts:
    paths:
      - gl-sbom-all.cdx.json
```

## Optimization

To optimize Dependency Scanning with SBOM according to your requirements you can:

- Exclude files and directories from the scan.
- Define the max depth to look for files.

### Exclude files and directories from the scan

To exclude files or directories from being scanned, use `DS_EXCLUDED_PATHS` with a comma-separated list of patterns in your `.gitlab-ci.yml`. This will prevent specified files and directories from being targeted by the scan.

### Define the max depth to look for files

To optimize the analyzer behavior you may set a max depth value through the `DS_MAX_DEPTH` environment variable. A value of `-1` scans all directories regardless of depth. The default is `2`.

## Roll out

After you are confident in the Dependency Scanning with SBOM results for a single project, you can extend its implementation to additional projects:

- Use [enforced scan execution](../../detect/security_configuration.md#create-a-shared-configuration) to apply Dependency Scanning with SBOM settings across groups.
- If you have unique requirements, Dependency Scanning with SBOM can be run in [offline environments](../../offline_deployments/_index.md).

## Supported package types

For the security analysis to be effective, the components listed in your SBOM report must have corresponding
entries in the [GitLab Advisory Database](../../gitlab_advisory_database/_index.md).

The GitLab SBOM Vulnerability Scanner can report Dependency Scanning vulnerabilities for components with the
following [PURL types](https://github.com/package-url/purl-spec/blob/346589846130317464b677bc4eab30bf5040183a/PURL-TYPES.rst):

- `cargo`
- `composer`
- `conan`
- `gem`
- `golang`
- `maven`
- `npm`
- `nuget`
- `pypi`

## Customizing analyzer behavior

How to customize the analyzer varies depending on the enablement solution.

{{< alert type="warning" >}}

Test all customization of GitLab analyzers in a merge request before merging these changes to the
default branch. Failure to do so can give unexpected results, including a large number of false
positives.

{{< /alert >}}

### Customizing behavior with the CI/CD template

When using the `latest` Dependency Scanning CI/CD template `Dependency-Scanning.latest.gitlab-ci.yml` or [Scan Execution Policies](../../policies/scan_execution_policies.md) use [CI/CD variables](#available-cicd-variables).

#### Available CI/CD variables

The following variables allow configuration of global dependency scanning settings.

| CI/CD variables             | Description |
| ----------------------------|------------ |
| `DS_EXCLUDED_ANALYZERS`     | Specify the analyzers (by name) to exclude from Dependency Scanning. |
| `DS_EXCLUDED_PATHS`         | Exclude files and directories from the scan based on the paths. A comma-separated list of patterns. Patterns can be globs (see [`doublestar.Match`](https://pkg.go.dev/github.com/bmatcuk/doublestar/v4@v4.0.2#Match) for supported patterns), or file or folder paths (for example, `doc,spec`). Parent directories also match patterns. This is a pre-filter which is applied before the scan is executed. Default: `"spec, test, tests, tmp"`. |
| `DS_MAX_DEPTH`              | Defines how many directory levels deep that the analyzer should search for supported files to scan. A value of `-1` scans all directories regardless of depth. Default: `2`. |
| `DS_INCLUDE_DEV_DEPENDENCIES` | When set to `"false"`, development dependencies are not reported. Only projects using Composer, Conda, Gradle, Maven, npm, pnpm, Pipenv, Poetry, or uv are supported. Default: `"true"` |
| `DS_PIPCOMPILE_REQUIREMENTS_FILE_NAME_PATTERN`   | Defines which requirement files to process using glob pattern matching (for example, `requirements*.txt` or `*-requirements.txt`). The pattern should match filenames only, not directory paths. See [glob pattern documentation](https://github.com/bmatcuk/doublestar/tree/v1?tab=readme-ov-file#patterns) for syntax details. |
| `SECURE_ANALYZERS_PREFIX`   | Override the name of the Docker registry providing the official default images (proxy). |
| `DS_FF_LINK_COMPONENTS_TO_GIT_FILES`   | Link components in the dependency list to files committed to the repository rather than lockfiles and graph files generated dynamically in a CI/CD pipeline. This ensures all components are linked to a source file in the repository. Default: `"false"`. |

##### Overriding dependency scanning jobs

To override a job definition declare a new job with the same name as the one to override.
Place this new job after the template inclusion and specify any additional keys under it.
For example, this configures the `dependencies: []` attribute for the dependency-scanning job:

```yaml
include:
  - template: Jobs/Dependency-Scanning.gitlab-ci.yml

dependency-scanning:
  dependencies: ["build"]
```

### Customizing behavior with the CI/CD component

When using the Dependency Scanning CI/CD component, the analyzer can be customized by configuring the [inputs](https://gitlab.com/explore/catalog/components/dependency-scanning).

## How it scans an application

The dependency scanning using SBOM approach relies on two distinct phases:

- First, the dependency detection phase that focuses solely on creating a comprehensive inventory of your
  project's dependencies and their relationship (dependency graph). This inventory is captured in an SBOM (Software Bill of Materials)
  document.
- Second, after the CI/CD pipeline completes, the GitLab platform processes your SBOM report and performs
  a thorough security analysis using the built-in GitLab SBOM Vulnerability Scanner. It is the same scanner
  that provides [Continuous Vulnerability Scanning](../../continuous_vulnerability_scanning/_index.md).

This separation of concerns and the modularity of this architecture allows to better support customers through expansion
of language support, a tighter integration and experience within the GitLab platform, and a shift towards industry standard
report types.

## Dependency detection

Dependency scanning using SBOM requires the detected dependencies to be captured in a CycloneDX SBOM document.
However, the modular aspect of this functionality allows you to select how this document is generated:

- Using the Dependency Scanning analyzer provided by GitLab (recommended)
- Using the (deprecated) Gemnasium analyzer provided by GitLab
- Using a custom job with a 3rd party CycloneDX SBOM generator or a custom tool.

To activate dependency scanning using SBOM, the provided CycloneDX SBOM document must:

- Comply with [the CycloneDX specification](https://github.com/CycloneDX/specification) version `1.4`, `1.5`, or `1.6`. Online validator available on [CycloneDX Web Tool](https://cyclonedx.github.io/cyclonedx-web-tool/validate).
- Comply with [the GitLab CycloneDX property taxonomy](../../../../development/sec/cyclonedx_property_taxonomy.md).
- Be uploaded as [a CI/CD artifact report](../../../../ci/yaml/artifacts_reports.md#artifactsreportscyclonedx) from a successful pipeline.

When using GitLab-provided analyzers, these requirements are met.

## Security analysis

After a compatible CycloneDX SBOM document is uploaded, GitLab automatically performs the security analysis
with the GitLab SBOM Vulnerability Scanner. Each component is checked against the GitLab Advisory Database and
scan results are processed in the following manners:

If the SBOM report is declared by a CI/CD job on the default branch: vulnerabilities are created,
and can be seen in the [vulnerability report](../../vulnerability_report/_index.md).

If the SBOM report is declared by a CI/CD job on a non-default branch: security findings are created,
and can be seen in the [security tab of the pipeline view](../../vulnerability_report/pipeline.md) and MR security widget.
This functionality is behind a feature flag and tracked in [Epic 14636](https://gitlab.com/groups/gitlab-org/-/epics/14636).

## Offline support

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

For instances in an environment with limited, restricted, or intermittent access
to external resources through the internet, you need to make some adjustments to run dependency scanning jobs successfully.
For more information, see [offline environments](../../offline_deployments/_index.md).

### Requirements

To run dependency scanning in an offline environment you must have:

- A GitLab Runner with the `docker` or `kubernetes` executor.
- Local copies of the dependency scanning analyzer images.
- Access to the [Package Metadata Database](../../../../topics/offline/quick_start_guide.md#enabling-the-package-metadata-database). Required to have license and advisory data for your dependencies.

### Local copies of analyzer images

To use the dependency scanning analyzer:

1. Import the following default dependency scanning analyzer images from `registry.gitlab.com` into
   your [local Docker container registry](../../../packages/container_registry/_index.md):

   ```plaintext
   registry.gitlab.com/security-products/dependency-scanning:v0
   ```

   The process for importing Docker images into a local offline Docker registry depends on
   **your network security policy**. Consult your IT staff to find an accepted and approved
   process by which external resources can be imported or temporarily accessed.
   These scanners are [periodically updated](../../detect/vulnerability_scanner_maintenance.md)
   with new definitions, and you may want to download them regularly. In case your offline instance
   has access to the GitLab registry you can use the [Security-Binaries template](../../offline_deployments/_index.md#using-the-official-gitlab-template) to download the latest dependency scanning analyzer image.

1. Configure GitLab CI/CD to use the local analyzers.

   Set the value of the CI/CD variable `SECURE_ANALYZERS_PREFIX` to your local Docker registry - in
   this example, `docker-registry.example.com`.

   ```yaml
   include:
     - template: Jobs/Dependency-Scanning.latest.gitlab-ci.yml

   variables:
     SECURE_ANALYZERS_PREFIX: "docker-registry.example.com/analyzers"
   ```

## Security policies

Use security policies to enforce Dependency Scanning across multiple projects.
The appropriate policy type depends on whether your projects have scannable artifacts committed to their repositories.

### Scan execution policies

[Scan execution policies](../../policies/scan_execution_policies.md) are supported for all projects that have scannable artifacts committed to their repositories. These artifacts include lockfiles, dependency graph files, and other files that can be directly analyzed to identify dependencies.

For projects with these artifacts, scan execution policies provide the fastest and most straightforward way to enforce Dependency Scanning.

### Pipeline execution policies

For projects that don't have scannable artifacts committed to their repositories,
you must use [pipeline execution policies](../../policies/pipeline_execution_policies.md).
These policies use a custom CI/CD job to generate scannable artifacts before invoking Dependency Scanning.

Pipeline execution policies:

- Generate lockfiles or dependency graphs as part of your CI/CD pipeline.
- Customize the dependency detection process for your specific project requirements.
- Implement the language-specific instructions for build tools like Gradle and Maven.

#### Example: Pipeline execution policy for a Gradle project

For a Gradle project without a scannable artifact committed to the repository, a pipeline execution policy with an artifact generation step is required. This example uses the `nebula` plugin.

In the dedicated security policies project create or update the main policy file (for example, `policy.yml`):

```yaml
pipeline_execution_policy:
- name: Enforce Gradle dependency scanning with SBOM
  description: Generate dependency artifact and run Dependency Scanning.
  enabled: true
  pipeline_config_strategy: inject_policy
  content:
    include:
      - project: $SECURITY_POLICIES_PROJECT
        file: "dependency-scanning.yml"
```

Add `dependency-scanning.yml`:

```yaml
stages:
  - build
  - test

variables:
  DS_ENFORCE_NEW_ANALYZER: "true"

include:
  - template: Jobs/Dependency-Scanning.latest.gitlab-ci.yml

generate nebula lockfile:
  image: openjdk:11-jdk
  stage: build
  script:
    - |
      cat << EOF > nebula.gradle
      initscript {
          repositories {
            mavenCentral()
          }
          dependencies {
              classpath 'com.netflix.nebula:gradle-dependency-lock-plugin:12.7.1'
          }
      }

      allprojects {
          apply plugin: nebula.plugin.dependencylock.DependencyLockPlugin
      }
      EOF
      ./gradlew --init-script nebula.gradle -PdependencyLock.includeTransitives=true -PdependencyLock.lockFile=dependencies.lock generateLock saveLock
      ./gradlew --init-script nebula.gradle -PdependencyLock.includeTransitives=false -PdependencyLock.lockFile=dependencies.direct.lock generateLock saveLock
  after_script:
    - find . -path '*/build/dependencies.lock' -print -delete
  artifacts:
    paths:
      - '**/dependencies.lock'
      - '**/dependencies.direct.lock'
```

This approach ensures that:

1. A pipeline run in the Gradle project generates the scannable artifacts.
1. Dependency Scanning is enforced and has access to the scannable artifacts.
1. All projects in the policy scope consistently follow the same dependency scanning approach.
1. Configuration changes can be managed centrally and applied across multiple projects.

For more details on implementing pipeline execution policies for different build tools, refer to the [language-specific instructions](#language-specific-instructions).

## Troubleshooting

When working with dependency scanning, you might encounter the following issues.

### Warning: `grep: command not found`

The analyzer image contains minimal dependencies to decrease the image's attack surface.
As a result, utilities commonly found in other images, like `grep`, are missing from the image.
This may result in a warning like `/usr/bin/bash: line 3: grep: command not found` to appear in
the job log. This warning does not impact the results of the analyzer and can be ignored.
