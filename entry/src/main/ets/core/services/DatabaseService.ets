import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { RitualModel, RitualType } from '../models/RitualModel';

export class DatabaseService {
  private static _instance: DatabaseService;
  private rdbStore: relationalStore.RdbStore | null = null;
  private context: common.Context;

  private constructor(context: common.Context) {
    this.context = context;
  }

  static async init(context: common.Context): Promise<DatabaseService> {
    if (!DatabaseService._instance) {
      DatabaseService._instance = new DatabaseService(context);
      await DatabaseService._instance.getStore();
    }
    return DatabaseService._instance;
  }

  static get instance(): DatabaseService {
    return DatabaseService._instance;
  }

  private async getStore(): Promise<relationalStore.RdbStore> {
    if (this.rdbStore) return this.rdbStore;

    const STORE_CONFIG: relationalStore.StoreConfig = {
      name: 'HabitTracker.db',
      securityLevel: relationalStore.SecurityLevel.S1,
    };

    const SQL_CREATE_TABLE = 'CREATE TABLE IF NOT EXISTS ritual (' +
      'id INTEGER PRIMARY KEY AUTO_INCREMENT, ' +
      'period_id INTEGER, ' +
      'title TEXT, ' +
      'time TEXT, ' +
      'color TEXT, ' +
      'completed INTEGER, ' +
      'type TEXT, ' +
      'target_value INTEGER)';

    this.rdbStore = await relationalStore.getRdbStore(this.context, STORE_CONFIG);
    await this.rdbStore.executeSql(SQL_CREATE_TABLE);
    return this.rdbStore;
  }

  async saveRitual(periodId: number, ritual: RitualModel): Promise<void> {
    const store = await this.getStore();
    const valueBucket: relationalStore.ValuesBucket = {
      'period_id': periodId,
      'title': ritual.title,
      'time': ritual.time,
      'color': ritual.color,
      'completed': ritual.completed ? 1 : 0,
      'type': ritual.type,
      'target_value': ritual.targetValue
    };
    await store.insert('ritual', valueBucket);
  }

  async updateRitual(ritual: RitualModel): Promise<void> {
    const store = await this.getStore();
    const valueBucket: relationalStore.ValuesBucket = {
      'completed': ritual.completed ? 1 : 0
    };
    const predicates = new relationalStore.RdbPredicates('ritual');
    predicates.equalTo('id', ritual.id);
    await store.update(valueBucket, predicates);
  }

  async loadRituals(periodId: number): Promise<RitualModel[]> {
    const store = await this.getStore();
    const predicates = new relationalStore.RdbPredicates('ritual');
    predicates.equalTo('period_id', periodId);
    const resultSet = await store.query(predicates);
    const rituals: RitualModel[] = [];
    while (resultSet.goToNextRow()) {
      rituals.push(new RitualModel(
        resultSet.getLong(resultSet.getColumnIndex('id')),
        resultSet.getString(resultSet.getColumnIndex('title')),
        resultSet.getString(resultSet.getColumnIndex('time')),
        resultSet.getString(resultSet.getColumnIndex('color')),
        resultSet.getLong(resultSet.getColumnIndex('completed')) === 1,
        resultSet.getString(resultSet.getColumnIndex('type')) as RitualType,
        resultSet.getLong(resultSet.getColumnIndex('target_value'))
      ));
    }
    resultSet.close();
    return rituals;
  }
}
