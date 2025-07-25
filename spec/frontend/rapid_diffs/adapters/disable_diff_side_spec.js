import { DiffFile } from '~/rapid_diffs/web_components/diff_file';
import { disableDiffSideAdapter } from '~/rapid_diffs/adapters/disable_diff_side';
import { INVISIBLE, VISIBLE } from '~/rapid_diffs/adapter_events';

describe('disableDiffSideAdapter', () => {
  const getComponent = () => document.querySelector('diff-file');
  const getSide = (type) => document.querySelector(`[data-position="${type}"]`);
  const getWrapper = () => document.querySelector('#wrapper');

  const mount = () => {
    const viewer = 'any';
    document.body.innerHTML = `
      <diff-file data-file-data='${JSON.stringify({ viewer })}'>
        <div id="wrapper">
          <div data-file-body>
            <div data-position="old"></div>
            <div data-position="new"></div>
          </div>
        </div>
      </diff-file>
    `;
    getComponent().mount({
      adapterConfig: { [viewer]: [disableDiffSideAdapter] },
      appData: {},
      observe: jest.fn(),
      unobserve: jest.fn(),
    });
  };

  const show = () => {
    getComponent().trigger(VISIBLE);
  };

  const hide = () => {
    getComponent().trigger(INVISIBLE);
  };

  beforeAll(() => {
    customElements.define('diff-file', DiffFile);
  });

  it.each`
    activeSide | disabledSide
    ${'old'}   | ${'new'}
    ${'new'}   | ${'old'}
  `('disables $disabledSide side', ({ activeSide, disabledSide }) => {
    mount();
    show();
    const active = getSide(activeSide);
    active.dispatchEvent(new MouseEvent('mousedown', { bubbles: true }));
    expect(getWrapper().dataset.disableDiffSide).toBe(disabledSide);
  });

  it.each`
    side
    ${'old'}
    ${'new'}
  `('does not disable $side side when invisible', ({ side }) => {
    mount();
    show();
    hide();
    const active = getSide(side);
    active.dispatchEvent(new MouseEvent('mousedown', { bubbles: true }));
    expect(getWrapper().dataset.disableDiffSide).toBe(undefined);
  });
});
