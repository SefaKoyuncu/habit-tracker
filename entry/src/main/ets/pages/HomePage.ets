import { PeriodModel } from '../core/models/PeriodModel';
import { PeriodService } from '../core/services/PeriodService';
import display from '@ohos.display';

@Component
export struct HomePage {
  @Consume('pageStack') pageStack: NavPathStack;
  @State controller: PeriodService = PeriodService.instance;
  @State screenWidth: number = 0;
  @State screenHeight: number = 0;

  private morningGradientColor: LinearGradient = new LinearGradient([
    { color: '#87CEEB', offset: 0.0 },
    { color: '#4ea5d7', offset: 1.0 }
  ]);
  private afternoonGradientColor: LinearGradient = new LinearGradient([
    { color: '#F4D03F', offset: 0.0 },
    { color: '#c8b049', offset: 1.0 }
  ]);
  private eveningGradientColor: LinearGradient = new LinearGradient([
    { color: '#2C3E50', offset: 0.0 },
    { color: '#1a365c', offset: 1.0 }
  ]);

  async aboutToAppear() {
    await this.controller.initializeData();
    try {
      const defaultDisplay = await display.getDefaultDisplaySync();
      this.screenWidth = defaultDisplay.width;
      this.screenHeight = defaultDisplay.height;
    } catch (err) {
      console.error('Failed to get display info:', err);
    }
  }

  private baseSize(): number {
    return Math.min(this.screenWidth || 200, this.screenHeight || 200);
  }

  private progressSize(): number {
    return this.baseSize() * 0.22;
  }

  private fontSmall(): number {
    return this.baseSize() * 0.045;
  }

  private fontMedium(): number {
    return this.baseSize() * 0.06;
  }

  @Builder
  private buildProgressRing(index: number, gradient: LinearGradient, label: string) {
    const period = this.controller.periods[index];
    const progress = period ? period.progress : 0;

    Column() {
      Stack() {
        Progress({ value: progress, total: 100, type: ProgressType.Ring })
          .width(this.progressSize())
          .height(this.progressSize())
          .style({ strokeWidth: 6 })
          .color(gradient)
          .backgroundColor('#222')

        Text(`${progress}%`)
          .fontSize(this.baseSize() * 0.04)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
      }
      .onClick(() => {
        if (period) {
          this.pageStack.pushPathByName('Period', period.id);
        }
      })

      Text(label)
        .fontSize(this.fontSmall())
        .margin({ top: 4 })
        .fontColor('#AAA')
    }
  }

  @Builder
  private buildProgressSection() {
    Column() {
      // Top Center Ring
      this.buildProgressRing(0, this.morningGradientColor, 'Morning')
        .margin({ top: 10 })

      // Side by Side Rings
      Row() {
        this.buildProgressRing(1, this.afternoonGradientColor, 'Afternoon')
        this.buildProgressRing(2, this.eveningGradientColor, 'Evening')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
      .margin({ top: 10, bottom: 20 })
    }
  }

  @Builder
  private buildPeriodCard(period: PeriodModel) {
    Row() {
      Column() {
        Text(period.title)
          .fontSize(this.fontMedium())
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White);
        Text(period.time)
          .fontSize(this.fontSmall())
          .fontColor('#BBB')
          .margin({ top: 2 });
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Circle({ width: 12, height: 12 })
        .fill(period.completed ? Color.Green : Color.Gray)
    }
    .width('92%')
    .padding(18)
    .margin({ bottom: 12 })
    .borderRadius(24)
    .backgroundColor('#1A1A1A')
    .border({ width: 1, color: '#333' })
    .onClick(() => {
      this.pageStack.pushPathByName('Period', period.id);
    });
  }

  build() {
    NavDestination() {
      if (!this.controller.isLoaded) {
        Column() {
          LoadingProgress().width(40).height(40).color(Color.White)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor(Color.Black)
      } else {
        Scroll() {
          Column() {
            // Header Space for Watch Curve
            Blank().height(30)

            this.buildProgressSection()

            ForEach(this.controller.periods, (period: PeriodModel) => {
              this.buildPeriodCard(period)
            }, (period: PeriodModel) => period.id.toString())

            // Footer Space for Watch Curve
            Blank().height(40)
          }
          .width('100%')
        }
        .width('100%')
        .height('100%')
        .backgroundColor(Color.Black)
        .scrollBar(BarState.Off)
      }
    }.onReady((ctx: NavDestinationContext) => {
      this.pageStack = ctx.pathStack;
    })
    .hideBackButton(true)
  }
}
