import { sensor } from '@kit.SensorServiceKit';
import { PeriodService } from './PeriodService';
import { RitualType } from '../models/RitualModel';

export class SensorTrackingService {
  private static _instance: SensorTrackingService;
  private periodService = PeriodService.instance;
  private isTracking: boolean = false;
  private currentSteps: number = 0;

  private constructor() {}

  static get instance(): SensorTrackingService {
    if (!SensorTrackingService._instance) {
      SensorTrackingService._instance = new SensorTrackingService();
    }
    return SensorTrackingService._instance;
  }

  startTracking() {
    if (this.isTracking) return;
    this.isTracking = true;

    try {
      // Subscribe to Pedometer
      sensor.on(sensor.SensorId.PEDOMETER, (data) => {
        this.handleStepUpdate(data.steps);
      }, { interval: 10000000 }); // 1 second

      console.log('Pedometer tracking started');
    } catch (err) {
      console.error('Failed to start pedometer:', err);
    }
  }

  stopTracking() {
    if (!this.isTracking) return;
    this.isTracking = false;
    try {
      sensor.off(sensor.SensorId.PEDOMETER);
    } catch (err) {
      console.error('Failed to stop pedometer:', err);
    }
  }

  private handleStepUpdate(steps: number) {
    this.currentSteps = steps;
    this.checkHabitCompletion();
  }

  private checkHabitCompletion() {
    // Check all periods for STEP-based rituals
    this.periodService.periods.forEach(period => {
      period.rituals.forEach(ritual => {
        if (!ritual.completed && ritual.type === RitualType.STEPS) {
          if (this.currentSteps >= ritual.targetValue) {
            this.periodService.toggleRitualCompletion(period.id, ritual.id);
            console.log(`Auto-completed ritual: ${ritual.title} based on steps: ${this.currentSteps}`);
          }
        }
      });
    });
  }
}
