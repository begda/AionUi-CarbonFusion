/**
 * @license
 * Copyright 2025 AionUi (aionui.com)
 * SPDX-License-Identifier: Apache-2.0
 */

import { getPlatformServices } from '@/common/platform';

/**
 * Returns baseName unchanged in release builds, or baseName + '-dev' in dev builds.
 * When AIONUI_MULTI_INSTANCE=1, appends '-2' to isolate the second dev instance.
 * Used to isolate symlink and directory names between environments.
 *
 * @example
 * getEnvAwareName('.carbonfusion')        // release → '.carbonfusion',        dev → '.carbonfusion-dev'  // shanzhake修改
 * getEnvAwareName('.carbonfusion-config') // release → '.carbonfusion-config', dev → '.carbonfusion-config-dev'  // shanzhake修改
 * // with CARBONFUSION_MULTI_INSTANCE=1:  dev → '.carbonfusion-dev-2'  // shanzhake修改
 */
export function getEnvAwareName(baseName: string): string {
  if (getPlatformServices().paths.isPackaged() === true) return baseName;
  const suffix = process.env.AIONUI_MULTI_INSTANCE === '1' ? '-dev-2' : '-dev';
  return `${baseName}${suffix}`;
}
