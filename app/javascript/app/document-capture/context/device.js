import { createContext } from 'react';

/**
 * @typedef VideoDeviceSupport
 *
 * @see https://www.w3.org/TR/mediacapture-streams/#dom-videofacingmodeenum
 *
 * @prop {Record<VideoFacingModeEnum,boolean>} facingMode Camera facing mode.
 */

/**
 * @typedef DeviceSupport
 *
 * @prop {VideoDeviceSupport} video Video device supports.
 */

/**
 * @typedef DeviceContext
 *
 * @prop {DeviceSupport} supports Device supports.
 */

const DeviceContext = createContext(
  /** @type {DeviceContext} */ ({
    supports: {
      video: {
        facingMode: {},
      },
    },
  }),
);

export default DeviceContext;
