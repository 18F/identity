import { renderHook } from '@testing-library/react-hooks';
import sinon from 'sinon';
import useForceRender from '@18f/identity-document-capture/hooks/use-force-render';

describe('document-capture/hooks/use-force-render', () => {
  it('returns a function', () => {
    const { result } = renderHook(() => useForceRender());

    expect(result.current).to.be.a('Function');
  });

  it('forces a render', () => {
    const callback = sinon.stub().callsFake(() => useForceRender());
    const { result } = renderHook(callback);

    expect(callback.calledOnce).to.be.true();
    result.current();
    expect(callback.calledTwice).to.be.true();
  });
});
