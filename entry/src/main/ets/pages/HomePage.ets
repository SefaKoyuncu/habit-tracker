import { PeriodModel } from '../core/models/PeriodModel';
import { PeriodService } from '../core/services/PeriodService';
import display from '@ohos.display';
import { hilog } from '@kit.PerformanceAnalysisKit';

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
    hilog.info(0x0001, 'HomePage', 'aboutToAppear');
    try {
      // Set a timeout for loading to prevent permanent loading screen
      setTimeout(() => {
        if (!this.controller.isLoaded) {
          hilog.warn(0x0001, 'HomePage', 'Loading timed out, forcing display');
          this.controller.isLoaded = true;
        }
      }, 3000);

      await this.controller.initializeData();
      const defaultDisplay = await display.getDefaultDisplaySync();
      this.screenWidth = defaultDisplay.width;
      this.screenHeight = defaultDisplay.height;
    } catch (err) {
      hilog.error(0x0001, 'HomePage', 'Error in aboutToAppear: %{public}s', JSON.stringify(err));
    }
  }

  private baseSize(): number {
    return Math.min(this.screenWidth || 240, this.screenHeight || 240);
  }

  private progressSize(): number {
    return this.baseSize() * 0.22;
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
        .fontSize(this.baseSize() * 0.045)
        .margin({ top: 4 })
        .fontColor('#AAA')
    }
  }

  @Builder
  private buildPeriodCard(period: PeriodModel) {
    Row() {
      Column() {
        Text(period.title)
          .fontSize(this.baseSize() * 0.06)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White);
        Text(period.time)
          .fontSize(this.baseSize() * 0.045)
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
    .onClick(() => {
      this.pageStack.pushPathByName('Period', period.id);
    });
  }

  build() {
    NavDestination() {
      Stack() {
        if (!this.controller.isLoaded) {
          Column() {
            LoadingProgress().width(50).height(50).color(Color.White)
            Text('Syncing Habits...').fontColor('#666').margin({ top: 10 })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .backgroundColor(Color.Black)
        } else {
          Scroll() {
            Column() {
              Blank().height(30)

              // Rings Section
              Column() {
                this.buildProgressRing(0, this.morningGradientColor, 'Morning')
                  .margin({ bottom: 15 })

                Row() {
                  this.buildProgressRing(1, this.afternoonGradientColor, 'Afternoon')
                  this.buildProgressRing(2, this.eveningGradientColor, 'Evening')
                }
                .width('100%')
                .justifyContent(FlexAlign.SpaceEvenly)
                .margin({ bottom: 25 })
              }

              ForEach(this.controller.periods, (period: PeriodModel) => {
                this.buildPeriodCard(period)
              }, (period: PeriodModel) => period.id.toString())

              Blank().height(60)
            }
            .width('100%')
          }
          .width('100%')
          .height('100%')
          .backgroundColor(Color.Black)
          .scrollBar(BarState.Off)
        }
      }
    }.onReady((ctx: NavDestinationContext) => {
      this.pageStack = ctx.pathStack;
    })
    .hideBackButton(true)
  }
}
