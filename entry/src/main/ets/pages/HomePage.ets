import { PeriodModel } from '../core/models/PeriodModel';
import { PeriodService } from '../core/services/PeriodService';
import display from '@ohos.display';

class PeriodDataSource implements IDataSource {
  private data: PeriodModel[] = [];
  private listeners: DataChangeListener[] = [];

  constructor(data: PeriodModel[]) {
    this.data = data || [];
  }

  totalCount(): number {
    return this.data.length;
  }

  getData(index: number): PeriodModel {
    return this.data[index];
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos = this.listeners.indexOf(listener);
    if (pos >= 0) {
      this.listeners.splice(pos, 1);
    }
  }

  notifyDataReload(): void {
    this.listeners.forEach(listener => listener.onDataReloaded());
  }

  notifyDataAdd(index: number): void {
    this.listeners.forEach(listener => listener.onDataAdd(index));
  }

  notifyDataChange(index: number): void {
    this.listeners.forEach(listener => listener.onDataChange(index));
  }

  notifyDataDelete(index: number): void {
    this.listeners.forEach(listener => listener.onDataDelete(index));
  }
}

@Component
export struct HomePage {
  @Consume('pageStack') pageStack: NavPathStack;
  private controller = PeriodService.instance;
  @State periodsProgress: number[] = [0, 0, 0];
  @State periodsDataSource: PeriodDataSource = new PeriodDataSource(this.controller.periods);
  @State screenWidth: number = 0;
  @State screenHeight: number = 0;

  private morningGradientColor: LinearGradient = new LinearGradient([
    { color: '#87CEEB', offset: 0.0 }, // Sky Blue
    { color: '#4ea5d7', offset: 1.0 }
  ]);
  private afternoonGradientColor: LinearGradient = new LinearGradient([
    { color: '#F4D03F', offset: 0.0 }, // Gold
    { color: '#c8b049', offset: 1.0 }
  ]);
  private eveningGradientColor: LinearGradient = new LinearGradient([
    { color: '#2C3E50', offset: 0.0 }, // Midnight Blue
    { color: '#1a365c', offset: 1.0 }
  ]);

  async aboutToAppear() {
    this.updateDataSource();
    this.updateProgress();
    try {
      const defaultDisplay = await display.getDefaultDisplaySync();
      this.screenWidth = defaultDisplay.width;
      this.screenHeight = defaultDisplay.height;
    } catch (err) {
      console.error('Failed to get display info:', err);
    }
  }

  onPageShow() {
    this.updateDataSource();
    this.updateProgress();
  }

  private updateDataSource() {
    this.periodsDataSource = new PeriodDataSource(this.controller.periods);
  }

  private updateProgress() {
    this.periodsProgress = [
      this.calculateProgress(0),
      this.calculateProgress(1),
      this.calculateProgress(2)
    ];
  }

  private calculateProgress(index: number): number {
    const period = this.controller.periods[index];
    if (!period || period.rituals.length === 0) {
      return 0;
    }
    return period.progress;
  }

  private baseSize(): number {
    return Math.min(this.screenWidth || 200, this.screenHeight || 200);
  }

  private progressSize(): number {
    return this.baseSize() * 0.18;
  }

  private fontSmall(): number {
    return this.baseSize() * 0.045;
  }

  private fontMedium(): number {
    return this.baseSize() * 0.055;
  }

  @Builder
  private buildProgressRings() {
    Column() {
      // Top Ring
      Column() {
        Progress({ value: this.periodsProgress[0], total: 100, type: ProgressType.Ring })
          .width(this.progressSize())
          .height(this.progressSize())
          .style({ strokeWidth: 5 })
          .color(this.morningGradientColor)
          .backgroundColor('#222')
        Text(`${this.periodsProgress[0]}%`)
          .fontSize(this.fontSmall())
          .margin({ top: 2 })
          .fontColor($r('app.color.text_primary'))
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .margin({ top: 24 })

      // Mid Row
      Row() {
        Column() {
          Progress({ value: this.periodsProgress[1], total: 100, type: ProgressType.Ring })
            .width(this.progressSize())
            .height(this.progressSize())
            .style({ strokeWidth: 5 })
            .color(this.afternoonGradientColor)
            .backgroundColor('#222')
          Text(`${this.periodsProgress[1]}%`)
            .fontSize(this.fontSmall())
            .margin({ top: 2 })
            .fontColor($r('app.color.text_primary'))
        }
        .width('50%')
        .alignItems(HorizontalAlign.Center)

        Column() {
          Progress({ value: this.periodsProgress[2], total: 100, type: ProgressType.Ring })
            .width(this.progressSize())
            .height(this.progressSize())
            .style({ strokeWidth: 5 })
            .color(this.eveningGradientColor)
            .backgroundColor('#222')
          Text(`${this.periodsProgress[2]}%`)
            .fontSize(this.fontSmall())
            .margin({ top: 2 })
            .fontColor($r('app.color.text_primary'))
        }
        .width('50%')
        .alignItems(HorizontalAlign.Center)
      }
      .margin({ top: 8, bottom: 12 })
    }
  }

  build() {
    NavDestination() {
      ArcList({ initialIndex: 0 }) {
        ArcListItem() {
          Column() {
            if (this.periodsProgress.every(p => p === 100)) {
              Text($r('app.string.all_completed'))
                .fontSize(this.fontMedium())
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.Green)
                .margin({ top: 10 })
            }
            this.buildProgressRings()
            Text($r('app.string.motivation_text'))
              .fontSize(this.fontMedium())
              .fontColor($r('app.color.text_primary'))
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 20 })
          }
          .width('100%')
        }

        LazyForEach(this.periodsDataSource, (period: PeriodModel) => {
          ArcListItem() {
            Row() {
              Column() {
                Text(period.title)
                  .fontSize(this.fontMedium())
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Color.White);
                Text(period.time)
                  .fontSize(this.fontSmall())
                  .fontColor('#DDD')
                  .margin({ top: 2 });
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Text(`${period.progress}%`)
                .fontSize(this.fontMedium())
                .fontColor(Color.White)
                .fontWeight(FontWeight.Bold)
            }
            .width('85%')
            .padding(16)
            .borderRadius(25)
            .backgroundColor(period.color)
            .onClick(() => {
              this.pageStack.pushPathByName('Period', period.id);
            });
          }
        }, (period: PeriodModel) => period.id.toString())
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.page_background'))
      .scrollBar(BarState.Off)
    }.onReady((ctx: NavDestinationContext) => {
      this.pageStack = ctx.pathStack;
    })
    .hideBackButton(true)
  }
}
