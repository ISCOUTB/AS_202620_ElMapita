import { Injectable } from '@nestjs/common';
import { LocationProvider, UserLocation, Coordinates } from '../../domain';

@Injectable()
export class PlatformLocationAdapter implements LocationProvider {
  async getCurrentLocation(): Promise<UserLocation> {
    return {
      coordinates: { latitude: 0, longitude: 0 },
      precisionMeters: 999,
      source: 'gps',
      timestamp: new Date(),
      uncertaintyShown: true,
    };
  }

  watchLocation(callback: (location: UserLocation) => void): () => void {
    return () => {};
  }

  async requestPermission(): Promise<boolean> {
    return true;
  }

  async isPermissionGranted(): Promise<boolean> {
    return true;
  }
}

@Injectable()
export class FakeLocationProvider implements LocationProvider {
  private locations: UserLocation[] = [
    {
      coordinates: { latitude: 10.3932, longitude: -75.5144 },
      precisionMeters: 5,
      floorEstimate: 1,
      source: 'gps',
      timestamp: new Date(),
      uncertaintyShown: false,
    },
    {
      coordinates: { latitude: 10.3935, longitude: -75.5147 },
      precisionMeters: 12,
      floorEstimate: 2,
      source: 'wifi',
      timestamp: new Date(),
      uncertaintyShown: true,
    },
  ];
  private index = 0;

  async getCurrentLocation(): Promise<UserLocation> {
    const location = this.locations[this.index % this.locations.length];
    this.index++;
    return location;
  }

  watchLocation(callback: (location: UserLocation) => void): () => void {
    const interval = setInterval(() => {
      callback(this.locations[this.index % this.locations.length]);
      this.index++;
    }, 5000);
    return () => clearInterval(interval);
  }

  async requestPermission(): Promise<boolean> {
    return true;
  }

  async isPermissionGranted(): Promise<boolean> {
    return true;
  }
}