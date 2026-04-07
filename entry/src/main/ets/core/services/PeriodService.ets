import { PeriodModel } from '../models/PeriodModel';
import { RitualModel, RitualType } from '../models/RitualModel';
import { DatabaseService } from './DatabaseService';

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
  private static _instance: PeriodService;
  private db = DatabaseService.instance;

  private constructor() {
    this.initializeData();
  }

  static get instance(): PeriodService {
    if (!PeriodService._instance) {
      PeriodService._instance = new PeriodService();
    }
    return PeriodService._instance;
  }

  private async initializeData(): Promise<void> {
    // 1. Try to load from DB
    let p1 = await this.db.loadRituals(1);
    let p2 = await this.db.loadRituals(2);
    let p3 = await this.db.loadRituals(3);

    // 2. If DB is empty, initialize with default data and save to DB
    if (p1.length === 0 && p2.length === 0 && p3.length === 0) {
      const defaultPeriods = [
        new PeriodModel(1, 'Morning Ritual', '06:00 - 09:00', '#4ea5d7', [
          new RitualModel(1, 'Drink water', '1 min', '#4ea5d7', true),
          new RitualModel(2, 'Morning Breath', '3 min', '#4ea5d7', false, RitualType.BREATHING, 180),
          new RitualModel(3, 'Quick Walk', '500 steps', '#4ea5d7', false, RitualType.STEPS, 500)
        ]),
        new PeriodModel(2, 'Afternoon Ritual', '12:00 - 14:00', '#c8b049', [
          new RitualModel(4, 'Short walk', '1000 steps', '#c8b049', false, RitualType.STEPS, 1000),
          new RitualModel(5, 'Healthy lunch', '30 min', '#c8b049', true)
        ]),
        new PeriodModel(3, 'Evening Ritual', '20:00 - 22:00', '#1a365c', [
          new RitualModel(6, 'Read a book', '20 min', '#1a365c', true),
          new RitualModel(7, 'Evening Meditate', '10 min', '#1a365c', false, RitualType.BREATHING, 600)
        ])
      ];

      for (const p of defaultPeriods) {
        for (const r of p.rituals) {
          await this.db.saveRitual(p.id, r);
        }
      }
      this.periods = defaultPeriods;
    } else {
      this.periods = [
        new PeriodModel(1, 'Morning Ritual', '06:00 - 09:00', '#4ea5d7', p1),
        new PeriodModel(2, 'Afternoon Ritual', '12:00 - 14:00', '#c8b049', p2),
        new PeriodModel(3, 'Evening Ritual', '20:00 - 22:00', '#1a365c', p3)
      ];
    }
  }

  getPeriods(): PeriodModel[] {
    return this.periods;
  }

  async addRitual(periodId: number, ritual: RitualInput): Promise<void> {
    const period = this.periods.find(p => p.id === periodId);
    if (period) {
      const newId = Math.max(0, ...period.rituals.map(r => r.id)) + 1;
      const newRitual = new RitualModel(
        newId,
        ritual.title,
        ritual.time,
        ritual.color,
        false,
        ritual.type || RitualType.NORMAL,
        ritual.targetValue || 0
      );
      period.rituals = [...period.rituals, newRitual];
      await this.db.saveRitual(periodId, newRitual);
    }
  }

  async toggleRitualCompletion(periodId: number, ritualId: number): Promise<void> {
    const periodIndex = this.periods.findIndex(p => p.id === periodId);
    if (periodIndex === -1) return;

    const ritualIndex = this.periods[periodIndex].rituals.findIndex(r => r.id === ritualId);
    if (ritualIndex === -1) return;

    const ritual = this.periods[periodIndex].rituals[ritualIndex];
    ritual.completed = !ritual.completed;

    // Persist to DB
    await this.db.updateRitual(ritual);

    // Update reference to trigger reactivity
    this.periods = [...this.periods];
  }

  getPeriodById(id: number): PeriodModel | undefined {
    return this.periods.find(period => period.id === id);
  }
}
