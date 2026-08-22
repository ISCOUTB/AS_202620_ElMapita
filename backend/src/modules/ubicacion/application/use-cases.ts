import { UseCase } from '../../../shared/kernel';
import { UserLocation, LocationProvider, ManualLocationInput, ManualLocationOutput, Coordinates, GetCurrentLocationOutput, SetManualLocationInput, SetManualLocationOutput, RequestLocationPermissionOutput } from '../domain';

export class GetCurrentLocationUseCase implements UseCase<void, GetCurrentLocationOutput> {
  constructor(private readonly locationProvider: LocationProvider) {}

  async execute(): Promise<GetCurrentLocationOutput> {
    const location = await this.locationProvider.getCurrentLocation();
    return { location };
  }
}

export class SetManualLocationUseCase implements UseCase<SetManualLocationInput, SetManualLocationOutput> {
  execute(input: SetManualLocationInput): Promise<SetManualLocationOutput> {
    const coordinates: Coordinates = {
      latitude: 0,
      longitude: 0,
    };

    const location: UserLocation = {
      coordinates,
      precisionMeters: 0,
      floorEstimate: input.floor,
      source: 'manual',
      timestamp: new Date(),
      uncertaintyShown: true,
    };

    return Promise.resolve({ location });
  }
}

export class RequestLocationPermissionUseCase implements UseCase<void, RequestLocationPermissionOutput> {
  constructor(private readonly locationProvider: LocationProvider) {}

  async execute(): Promise<RequestLocationPermissionOutput> {
    const granted = await this.locationProvider.requestPermission();
    return { granted };
  }
}