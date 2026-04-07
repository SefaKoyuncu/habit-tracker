export enum RitualType {
  NORMAL = 'normal',
  BREATHING = 'breathing',
  STEPS = 'steps'
}

@ObservedV2
export class RitualModel {
  @Trace id: number;
  @Trace title: string;
  @Trace time: string;
  @Trace color: string;
  @Trace completed: boolean;
  @Trace type: RitualType;
  @Trace targetValue: number; // For steps or duration

  constructor(
    id: number,
    title: string,
    time: string,
    color: string,
    completed: boolean = false,
    type: RitualType = RitualType.NORMAL,
    targetValue: number = 0
  ) {
    this.id = id;
    this.title = title;
    this.time = time;
    this.color = color;
    this.completed = completed;
    this.type = type;
    this.targetValue = targetValue;
  }
}
