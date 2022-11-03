import type { Frame } from 'react-native-vision-camera';

export function detectObjectsML(frame: Frame) {
  'worklet';
  // @ts-ignore
  return __detectObjectsML(frame);
}
