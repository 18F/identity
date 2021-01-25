import { useRef, useEffect } from 'react';

/**
 * A hook behaving the same as useEffect in invoking the given callback when dependencies change,
 * but does not call the callback during initial mount.
 *
 * @type {typeof useEffect}
 */
function useDidUpdateEffect(callback, deps) {
  const isMounting = useRef(true);

  useEffect(() => {
    if (isMounting.current) {
      isMounting.current = false;
    } else {
      callback();
    }
  }, deps);
}

export default useDidUpdateEffect;
