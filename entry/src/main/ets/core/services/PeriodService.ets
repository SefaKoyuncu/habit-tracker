import { PeriodModel } from '../models/PeriodModel';
import { RitualModel, RitualType } from '../models/RitualModel';
import { DatabaseService } from './DatabaseService';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'PeriodService';
const DOMAIN = 0x0001;

export interface RitualInput {
  title: string;
  time: string;
  color: string;
  type?: RitualType;
  targetValue?: number;
}

@ObservedV2
export class PeriodService {
  @Trace periods: PeriodModel[] = [];
  @Trace isLoaded: boolean = false;
  private static _instance: PeriodService;
  private initializationPromise: Promise<void> | null = null;

  private constructor() {}

  static get instance(): PeriodService {
    if (!PeriodService._instance) {
      PeriodService._instance = new PeriodService();
    }
    return PeriodService._instance;
  }

  async initializeData(): Promise<void> {
    if (this.isLoaded) return;
    if (this.initializationPromise) return this.initializationPromise;

    this.initializationPromise = this._doInitialize();
    return this.initializationPromise;
  }

  private async _doInitialize(): Promise<void> {
    try {
      hilog.info(DOMAIN, TAG, 'Initializing data...');
      const db = DatabaseService.instance;
      if (!db) {
        hilog.error(DOMAIN, TAG, 'DatabaseService instance is null');
        this._loadFallbackData();
        return;
      }

      let p1 = await db.loadRituals(1);
      let p2 = await db.loadRituals(2);
      let p3 = await db.loadRituals(3);

      if (p1.length === 0 && p2.length === 0 && p3.length === 0) {
        hilog.info(DOMAIN, TAG, 'DB is empty, loading default data');
        const defaultPeriods = this._getDefaultData();
        for (const p of defaultPeriods) {
          for (const r of p.rituals) {
            await db.saveRitual(p.id, r);
          }
        }
        this.periods = defaultPeriods;
      } else {
        hilog.info(DOMAIN, TAG, 'Data loaded from DB');
        this.periods = [
          new PeriodModel(1, 'Morning Ritual', '06:00 - 09:00', '#4ea5d7', p1),
          new PeriodModel(2, 'Afternoon Ritual', '12:00 - 14:00', '#c8b049', p2),
          new PeriodModel(3, 'Evening Ritual', '20:00 - 22:00', '#1a365c', p3)
        ];
      }
      this.isLoaded = true;
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to initialize: %{public}s', JSON.stringify(err));
      this._loadFallbackData();
    }
  }

  private _loadFallbackData(): void {
    this.periods = this._getDefaultData();
    this.isLoaded = true;
  }

  private _getDefaultData(): PeriodModel[] {
    return [
      new PeriodModel(1, 'Morning Ritual', '06:00 - 09:00', '#4ea5d7', [
        new RitualModel(1, 'Drink water', '1 min', '#4ea5d7', false),
        new RitualModel(2, 'Morning Breath', '3 min', '#4ea5d7', false, RitualType.BREATHING, 180),
        new RitualModel(3, 'Quick Walk', '500 steps', '#4ea5d7', false, RitualType.STEPS, 500)
      ]),
      new PeriodModel(2, 'Afternoon Ritual', '12:00 - 14:00', '#c8b049', [
        new RitualModel(4, 'Short walk', '1000 steps', '#c8b049', false, RitualType.STEPS, 1000),
        new RitualModel(5, 'Healthy lunch', '30 min', '#c8b049', false)
      ]),
      new PeriodModel(3, 'Evening Ritual', '20:00 - 22:00', '#1a365c', [
        new RitualModel(6, 'Read a book', '20 min', '#1a365c', false),
        new RitualModel(7, 'Evening Meditate', '10 min', '#1a365c', false, RitualType.BREATHING, 600)
      ])
    ];
  }

  async toggleRitualCompletion(periodId: number, ritualId: number): Promise<void> {
    const period = this.periods.find(p => p.id === periodId);
    if (!period) return;
    const ritual = period.rituals.find(r => r.id === ritualId);
    if (!ritual) return;

    ritual.completed = !ritual.completed;
    try {
      await DatabaseService.instance.updateRitual(ritual);
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'DB Update failed: %{public}s', JSON.stringify(e));
    }
    this.periods = [...this.periods];
  }

  getPeriodById(id: number): PeriodModel | undefined {
    return this.periods.find(period => period.id === id);
  }
}
