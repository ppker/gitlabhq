# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Nuget::SearchService, feature_category: :package_registry do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:project) { create(:project, namespace: subgroup) }
  let_it_be_with_refind(:package_a) { create(:nuget_package, project: project, name: 'DummyPackageA') }
  let_it_be(:packages_b) { create_list(:nuget_package, 5, project: project, name: 'DummyPackageB') }
  let_it_be(:packages_c) { create_list(:nuget_package, 5, project: project, name: 'DummyPackageC') }
  let_it_be(:package_d) { create(:nuget_package, project: project, name: 'FooBarD') }
  let_it_be(:other_package_a) { create(:nuget_package, name: 'DummyPackageA') }
  let_it_be(:other_package_b) { create(:nuget_package, name: 'DummyPackageB') }

  let(:search_term) { 'ummy' }
  let(:per_page) { 5 }
  let(:padding) { 0 }
  let(:include_prerelease_versions) { true }
  let(:options) { { include_prerelease_versions: include_prerelease_versions, per_page: per_page, padding: padding } }

  describe '#execute' do
    subject { described_class.new(user, target, search_term, options).execute }

    shared_examples 'handling all the conditions' do |factory: :nuget_package|
      it { expect_search_results 3, package_a, packages_b, packages_c }

      context 'with a smaller per page count' do
        let(:per_page) { 2 }

        it { expect_search_results 3, package_a, packages_b }
      end

      context 'with 0 per page count' do
        let(:per_page) { 0 }

        it { expect_search_results 3, [] }
      end

      context 'with a negative per page count' do
        let(:per_page) { -1 }

        it { expect { subject }.to raise_error(ArgumentError, 'negative per_page') }
      end

      context 'with a padding' do
        let(:padding) { 2 }

        it { expect_search_results 3, packages_c }
      end

      context 'with a too big padding' do
        let(:padding) { 5 }

        it { expect_search_results 3, [] }
      end

      context 'with a negative padding' do
        let(:padding) { -1 }

        it { expect { subject }.to raise_error(ArgumentError, 'negative padding') }
      end

      context 'with search term' do
        let(:search_term) { 'umm' }

        it { expect_search_results 3, package_a, packages_b, packages_c }
      end

      context 'with nil search term' do
        let(:search_term) { nil }

        it { expect_search_results 4, package_a, packages_b, packages_c, package_d }
      end

      context 'with empty search term' do
        let(:search_term) { '' }

        it { expect_search_results 4, package_a, packages_b, packages_c, package_d }
      end

      context 'with non-installable packages' do
        let(:search_term) { '' }

        before do
          package_a.update_column(:status, 2)
        end

        it { expect_search_results 3, packages_b, packages_c, package_d }
      end

      context 'with prefix search term' do
        let(:search_term) { 'dummy' }

        it { expect_search_results 3, package_a, packages_b, packages_c }
      end

      context 'with suffix search term' do
        let(:search_term) { 'packagec' }

        it { expect_search_results 1, packages_c }
      end

      context 'with pre release packages' do
        let_it_be(:package_e) do
          create(factory, project: project, name: 'DummyPackageE', version: '3.2.1-alpha')
        end

        context 'when including them' do
          it { expect_search_results 4, package_a, packages_b, packages_c, package_e }
        end

        context 'when excluding them' do
          let(:include_prerelease_versions) { false }

          it { expect_search_results 3, package_a, packages_b, packages_c }

          context 'when mixed with release versions' do
            let_it_be(:package_e_release) do
              create(factory, project: project, name: 'DummyPackageE', version: '3.2.1')
            end

            it { expect_search_results 4, package_a, packages_b, packages_c, package_e_release }
          end
        end
      end
    end

    context 'with project' do
      let(:target) { project }

      before_all do
        project.add_developer(user)
      end

      it_behaves_like 'handling all the conditions'
    end

    context 'with subgroup' do
      let(:target) { subgroup }

      before_all do
        subgroup.add_developer(user)
      end

      it_behaves_like 'handling all the conditions'
    end

    context 'with group' do
      let(:target) { group }

      context 'when user is a group member' do
        before_all do
          group.add_developer(user)
        end

        it_behaves_like 'handling all the conditions'
      end

      context 'when user is not a group member' do
        context 'with public registry in private group' do
          before_all do
            [subgroup, group, project].each do |entity|
              entity.reload.update_column(:visibility_level, Gitlab::VisibilityLevel.const_get(:PRIVATE, false))
            end
            project.project_feature.update!(package_registry_access_level: ::ProjectFeature::PUBLIC)
          end

          before do
            stub_application_setting(package_registry_allow_anyone_to_pull_option: true)
          end

          it_behaves_like 'handling all the conditions'
        end
      end
    end

    def expect_search_results(total_count, *results)
      search = subject

      expect(search.total_count).to eq total_count
      expect(search.results).to match_array(Array.wrap(results).flatten)
    end
  end
end
