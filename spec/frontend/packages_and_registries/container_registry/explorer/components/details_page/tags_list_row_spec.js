import {
  GlFormCheckbox,
  GlSprintf,
  GlIcon,
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
} from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import { nextTick } from 'vue';

import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

import component from '~/packages_and_registries/container_registry/explorer/components/details_page/tags_list_row.vue';
import {
  REMOVE_TAG_BUTTON_TITLE,
  MISSING_MANIFEST_WARNING_TOOLTIP,
  NOT_AVAILABLE_TEXT,
  NOT_AVAILABLE_SIZE,
  COPY_IMAGE_PATH_TITLE,
} from '~/packages_and_registries/container_registry/explorer/constants/index';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import DetailsRow from '~/vue_shared/components/registry/details_row.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

import { tagsMock } from '../../mock_data';
import { ListItem } from '../../stubs';

describe('tags list row', () => {
  let wrapper;
  const [tag] = [...tagsMock];

  const defaultProps = { tag, isMobile: false, index: 0 };

  const findCheckbox = () => wrapper.findComponent(GlFormCheckbox);
  const findName = () => wrapper.find('[data-testid="name"]');
  const findSize = () => wrapper.find('[data-testid="size"]');
  const findTime = () => wrapper.find('[data-testid="time"]');
  const findShortRevision = () => wrapper.find('[data-testid="digest"]');
  const findClipboardButton = () => wrapper.findComponent(ClipboardButton);
  const findTimeAgoTooltip = () => wrapper.findComponent(TimeAgoTooltip);
  const findDetailsRows = () => wrapper.findAllComponents(DetailsRow);
  const findPublishedDateDetail = () => wrapper.find('[data-testid="published-date-detail"]');
  const findManifestDetail = () => wrapper.find('[data-testid="manifest-detail"]');
  const findConfigurationDetail = () => wrapper.find('[data-testid="configuration-detail"]');
  const findWarningIcon = () => wrapper.findComponent(GlIcon);
  const findAdditionalActionsMenu = () => wrapper.findComponent(GlDisclosureDropdown);
  const findDeleteButton = () => wrapper.findComponent(GlDisclosureDropdownItem);

  const mountComponent = (propsData = defaultProps, mountFn = shallowMount) => {
    wrapper = mountFn(component, {
      stubs: {
        GlSprintf,
        ListItem,
        DetailsRow,
        GlDisclosureDropdown,
        GlDisclosureDropdownItem,
      },
      propsData,
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  describe('checkbox', () => {
    it('exists', () => {
      mountComponent();

      expect(findCheckbox().exists()).toBe(true);
    });

    it("does not exist when the row can't be deleted", () => {
      const customTag = { ...tag, canDelete: false };

      mountComponent({ ...defaultProps, tag: customTag });

      expect(findCheckbox().exists()).toBe(false);
    });

    it.each`
      digest   | disabled | isDisabled
      ${'foo'} | ${true}  | ${'true'}
      ${null}  | ${true}  | ${'true'}
      ${null}  | ${false} | ${undefined}
      ${'foo'} | ${false} | ${undefined}
    `(
      'disabled attribute is set to $isDisabled when the digest $digest and disabled is $disabled',
      ({ digest, disabled, isDisabled }) => {
        mountComponent({ tag: { ...tag, digest }, disabled });

        expect(findCheckbox().attributes('disabled')).toBe(isDisabled);
      },
    );

    it('is wired to the selected prop', () => {
      mountComponent({ ...defaultProps, selected: true });

      expect(findCheckbox().attributes('checked')).toBe('true');
    });

    it('when changed emit a select event', () => {
      mountComponent();

      findCheckbox().vm.$emit('change');

      expect(wrapper.emitted('select')).toEqual([[]]);
    });
  });

  describe('tag name', () => {
    it('exists', () => {
      mountComponent();

      expect(findName().exists()).toBe(true);
    });

    it('has the correct text', () => {
      mountComponent();

      expect(findName().text()).toBe(tag.name);
    });

    it('has a tooltip', () => {
      mountComponent();

      const tooltip = getBinding(findName().element, 'gl-tooltip');

      expect(tooltip.value.title).toBe(tag.name);
    });

    it('on mobile has mw-s class', () => {
      mountComponent({ ...defaultProps, isMobile: true });

      expect(findName().classes('mw-s')).toBe(true);
    });
  });

  describe('clipboard button', () => {
    it('exist if tag.location exist', () => {
      mountComponent();

      expect(findClipboardButton().exists()).toBe(true);
    });

    it('is hidden if tag does not have a location', () => {
      mountComponent({ ...defaultProps, tag: { ...tag, location: null } });

      expect(findClipboardButton().exists()).toBe(false);
    });

    it('has the correct props/attributes', () => {
      mountComponent();

      expect(findClipboardButton().attributes()).toMatchObject({
        text: tag.location,
        title: COPY_IMAGE_PATH_TITLE,
      });
    });

    it('is disabled when the component is disabled', () => {
      mountComponent({ ...defaultProps, disabled: true });

      expect(findClipboardButton().attributes('disabled')).toBeDefined();
    });
  });

  describe('warning icon', () => {
    it('is normally hidden', () => {
      mountComponent();

      expect(findWarningIcon().exists()).toBe(false);
    });

    it('is shown when the tag is broken', () => {
      mountComponent({ tag: { ...tag, digest: null } });

      expect(findWarningIcon().exists()).toBe(true);
    });

    it('has an appropriate tooltip', () => {
      mountComponent({ tag: { ...tag, digest: null } });

      const tooltip = getBinding(findWarningIcon().element, 'gl-tooltip');
      expect(tooltip.value.title).toBe(MISSING_MANIFEST_WARNING_TOOLTIP);
    });
  });

  describe('size', () => {
    it('exists', () => {
      mountComponent();

      expect(findSize().exists()).toBe(true);
    });

    it('contains the totalSize and layers', () => {
      mountComponent({ ...defaultProps, tag: { ...tag, totalSize: '1024', layers: 10 } });

      expect(findSize().text()).toMatchInterpolatedText('1.00 KiB · 10 layers');
    });

    it('when totalSize is giantic', () => {
      mountComponent({ ...defaultProps, tag: { ...tag, totalSize: '1099511627776', layers: 2 } });

      expect(findSize().text()).toMatchInterpolatedText('1,024.00 GiB · 2 layers');
    });

    it('when totalSize is missing', () => {
      mountComponent({ ...defaultProps, tag: { ...tag, totalSize: '0', layers: 10 } });

      expect(findSize().text()).toMatchInterpolatedText(`${NOT_AVAILABLE_SIZE} · 10 layers`);
    });

    it('when layers are missing', () => {
      mountComponent({ ...defaultProps, tag: { ...tag, totalSize: '1024' } });

      expect(findSize().text()).toMatchInterpolatedText('1.00 KiB');
    });

    it('when there is 1 layer', () => {
      mountComponent({ ...defaultProps, tag: { ...tag, totalSize: '0', layers: 1 } });

      expect(findSize().text()).toMatchInterpolatedText(`${NOT_AVAILABLE_SIZE} · 1 layer`);
    });
  });

  describe('time', () => {
    it('exists', () => {
      mountComponent();

      expect(findTime().exists()).toBe(true);
    });

    it('has the correct text', () => {
      mountComponent();

      expect(findTime().text()).toBe('Published');
    });

    it('contains time_ago_tooltip component', () => {
      mountComponent();

      expect(findTimeAgoTooltip().exists()).toBe(true);
    });

    it('passes publishedAt value to time ago tooltip', () => {
      mountComponent();

      expect(findTimeAgoTooltip().attributes()).toMatchObject({ time: tag.publishedAt });
    });

    describe('when publishedAt is missing', () => {
      beforeEach(() => {
        mountComponent({ ...defaultProps, tag: { ...tag, publishedAt: null } });
      });

      it('passes createdAt value to time ago tooltip', () => {
        expect(findTimeAgoTooltip().attributes()).toMatchObject({ time: tag.createdAt });
      });
    });
  });

  describe('digest', () => {
    it('exists', () => {
      mountComponent();

      expect(findShortRevision().exists()).toBe(true);
    });

    it('has the correct text', () => {
      mountComponent();

      expect(findShortRevision().text()).toMatchInterpolatedText('Digest: 2cf3d2f');
    });

    it(`displays ${NOT_AVAILABLE_TEXT} when digest is missing`, () => {
      mountComponent({ tag: { ...tag, digest: null } });

      expect(findShortRevision().text()).toMatchInterpolatedText(`Digest: ${NOT_AVAILABLE_TEXT}`);
    });
  });

  describe('additional actions menu', () => {
    it('exists', () => {
      mountComponent();

      expect(findAdditionalActionsMenu().exists()).toBe(true);
    });

    it('has the correct props', () => {
      mountComponent();

      expect(findAdditionalActionsMenu().props()).toMatchObject({
        icon: 'ellipsis_v',
        toggleText: 'More actions',
        textSrOnly: true,
        category: 'tertiary',
        placement: 'right',
        disabled: false,
      });
    });

    it('has the correct classes', () => {
      mountComponent();

      expect(findAdditionalActionsMenu().classes('gl-opacity-0')).toBe(false);
      expect(findAdditionalActionsMenu().classes('gl-pointer-events-none')).toBe(false);
    });

    it('is not rendered when tag.canDelete is false', () => {
      mountComponent({ ...defaultProps, tag: { ...tag, canDelete: false } });

      expect(findAdditionalActionsMenu().exists()).toBe(false);
    });

    it('is hidden when disabled prop is set to true', () => {
      mountComponent({ ...defaultProps, disabled: true });

      expect(findAdditionalActionsMenu().props('disabled')).toBe(true);
      expect(findAdditionalActionsMenu().classes('gl-opacity-0')).toBe(true);
      expect(findAdditionalActionsMenu().classes('gl-pointer-events-none')).toBe(true);
    });

    describe('delete button', () => {
      it('exists and has the correct attrs', () => {
        mountComponent();

        expect(findDeleteButton().exists()).toBe(true);
        expect(findDeleteButton().props('item').extraAttrs).toMatchObject({
          class: 'gl-text-red-500!',
          'data-testid': 'single-delete-button',
        });

        expect(findDeleteButton().text()).toBe(REMOVE_TAG_BUTTON_TITLE);
      });

      it('delete event emits delete', () => {
        mountComponent(undefined, mount);

        wrapper.find('[data-testid="single-delete-button"]').trigger('click');

        expect(wrapper.emitted('delete')).toEqual([[]]);
      });
    });
  });

  describe('details rows', () => {
    describe('when the tag has a digest', () => {
      it('has 3 details rows', async () => {
        mountComponent();
        await nextTick();

        expect(findDetailsRows().length).toBe(3);
      });

      it('has 2 details rows when revision is empty', async () => {
        mountComponent({ tag: { ...tag, revision: '' } });
        await nextTick();

        expect(findDetailsRows().length).toBe(2);
      });

      describe.each`
        name                       | finderFunction             | text                                                                                                    | icon            | clipboard
        ${'published date detail'} | ${findPublishedDateDetail} | ${'Published to the gitlab-org/gitlab-test/rails-12009 image repository at 13:29:38 UTC on 2020-11-05'} | ${'clock'}      | ${false}
        ${'manifest detail'}       | ${findManifestDetail}      | ${'Manifest digest: sha256:2cf3d2fdac1b04a14301d47d51cb88dcd26714c74f91440eeee99ce399089062'}           | ${'log'}        | ${true}
        ${'configuration detail'}  | ${findConfigurationDetail} | ${'Configuration digest: sha256:c2613843ab33aabf847965442b13a8b55a56ae28837ce182627c0716eb08c02b'}      | ${'cloud-gear'} | ${true}
      `('$name details row', ({ finderFunction, text, icon, clipboard }) => {
        it(`has ${text} as text`, async () => {
          mountComponent();
          await nextTick();

          expect(finderFunction().text()).toMatchInterpolatedText(text);
        });

        it(`has the ${icon} icon`, async () => {
          mountComponent();
          await nextTick();

          expect(finderFunction().props('icon')).toBe(icon);
        });

        if (clipboard) {
          it(`clipboard button exist`, async () => {
            mountComponent();
            await nextTick();

            expect(finderFunction().findComponent(ClipboardButton).exists()).toBe(clipboard);
          });

          it('is disabled when the component is disabled', async () => {
            mountComponent({ ...defaultProps, disabled: true });
            await nextTick();

            expect(finderFunction().findComponent(ClipboardButton).attributes('disabled')).toBe(
              'true',
            );
          });
        }
      });

      describe('when publishedAt is missing', () => {
        beforeEach(() => {
          mountComponent({ ...defaultProps, tag: { ...tag, publishedAt: null } });
        });

        it('name details row has correct text', () => {
          expect(findPublishedDateDetail().text()).toMatchInterpolatedText(
            'Published to the gitlab-org/gitlab-test/rails-12009 image repository at 13:29:38 UTC on 2020-11-03',
          );
        });
      });
    });

    describe('when the tag does not have a digest', () => {
      it('hides the details rows', async () => {
        mountComponent({ tag: { ...tag, digest: null } });

        await nextTick();
        expect(findDetailsRows().length).toBe(0);
      });
    });
  });
});
