import { ValueObject } from '../../../shared/kernel';

export type Coordinates = {
  latitude: number;
  longitude: number;
};

export type PrecisionLevel = 'high' | 'medium' | 'low' | 'manual';

export interface UserLocation {
  coordinates: Coordinates;
  precisionMeters: number;
  floorEstimate?: number;
  source: LocationSource;
  timestamp: Date;
  uncertaintyShown: boolean;
}

export type LocationSource = 'gps' | 'wifi' | 'ble' | 'manual';

export interface LocationProvider {
  getCurrentLocation(): Promise<UserLocation>;
  watchLocation(callback: (location: UserLocation) => void): () => void;
  requestPermission(): Promise<boolean>;
  isPermissionGranted(): Promise<boolean>;
}

export interface ManualLocationInput {
  buildingId: string;
  floor: number;
  x: number;
  y: number;
}

export interface ManualLocationOutput {
  location: UserLocation;
}

// Use Case DTOs
export interface GetCurrentLocationOutput {
  location: UserLocation;
}

export interface SetManualLocationInput {
  buildingId: string;
  floor: number;
  x: number;
  y: number;
}

export interface SetManualLocationOutput {
  location: UserLocation;
}

export interface RequestLocationPermissionOutput {
  granted: boolean;
}