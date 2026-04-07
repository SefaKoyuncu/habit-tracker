import { PeriodService } from '../core/services/PeriodService';
import { RitualType } from '../core/models/RitualModel';
import display from '@ohos.display';
import { vibrator } from '@kit.SensorServiceKit';

interface RitualDisplay {
  id: number;
  title: string;
  time: string;
  color: string;
  type: RitualType;
  targetValue: number;
}

@Component
export struct Period {
  @Consume('pageStack') pageStack: NavPathStack;
  private controller = PeriodService.instance;
  @State periodId: number = -1;
  @State currentRitual: RitualDisplay | null = null;
  @State showCompletionMessage: boolean = false;
  @State screenWidth: number = 0;
  @State screenHeight: number = 0;

  // Breathing state
  @State isBreathing: boolean = false;
  @State breathProgress: number = 0;
  @State breathTimer: number = 0;
  private breathIntervalId: number = -1;

  async aboutToAppear(): Promise<void> {
    try {
      const defaultDisplay = await display.getDefaultDisplaySync();
      this.screenWidth = defaultDisplay.width;
      this.screenHeight = defaultDisplay.height;
    } catch (err) {
      console.error('Failed to get display info:', err);
    }
  }

  aboutToDisappear() {
    this.stopBreathing();
  }

  private loadNextRitual(): void {
    const period = this.controller.getPeriodById(this.periodId);
    if (!period) {
      this.pageStack.pop()
      return;
    }
    const nextRitual = period.rituals.find(r => !r.completed);
    this.showCompletionMessage = !nextRitual;
    if (nextRitual) {
      this.currentRitual = {
        id: nextRitual.id,
        title: nextRitual.title,
        time: nextRitual.time,
        color: nextRitual.color,
        type: nextRitual.type,
        targetValue: nextRitual.targetValue
      };
    } else {
      this.currentRitual = null;
    }
  }

  private completeCurrentRitual(): void {
    if (!this.currentRitual) return;
    this.stopBreathing();
    this.controller.toggleRitualCompletion(this.periodId, this.currentRitual.id);
    this.loadNextRitual();
  }

  private startBreathing() {
    if (!this.currentRitual || this.isBreathing) return;
    this.isBreathing = true;
    this.breathTimer = this.currentRitual.targetValue;

    this.breathIntervalId = setInterval(() => {
      if (this.breathTimer > 0) {
        this.breathTimer--;
        // Simple haptic pattern: vibrate every 4 seconds (breath cycle)
        if (this.breathTimer % 4 === 0) {
          this.triggerHaptic('haptic.clock.timer');
        }
      } else {
        this.completeCurrentRitual();
      }
    }, 1000);
  }

  private stopBreathing() {
    this.isBreathing = false;
    if (this.breathIntervalId !== -1) {
      clearInterval(this.breathIntervalId);
      this.breathIntervalId = -1;
    }
  }

  private triggerHaptic(effectId: string) {
    try {
      vibrator.startVibration({
        type: 'preset',
        effectId: effectId,
        count: 1
      }, {
        usage: 'alarm'
      });
    } catch (err) {
      console.error('Haptic failed:', err);
    }
  }

  private baseSize(): number {
    return Math.min(this.screenWidth || 200, this.screenHeight || 200);
  }

  @Builder
  private renderBreathingUI() {
    Column() {
      Stack() {
        Progress({ value: this.breathTimer, total: this.currentRitual?.targetValue || 100, type: ProgressType.Ring })
          .width(this.baseSize() * 0.6)
          .height(this.baseSize() * 0.6)
          .style({ strokeWidth: 10 })
          .color(this.currentRitual?.color || Color.Blue)

        Column() {
          Text(`${this.breathTimer}s`)
            .fontSize(this.baseSize() * 0.1)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
          Text('Breathe...')
            .fontSize(this.baseSize() * 0.05)
            .fontColor('#AAA')
        }
      }
      .margin({ bottom: 20 })

      Button(this.isBreathing ? 'Pause' : 'Start')
        .onClick(() => this.isBreathing ? this.stopBreathing() : this.startBreathing())
        .width('60%')
        .backgroundColor(this.isBreathing ? Color.Gray : Color.Green)
    }
  }

  build() {
    NavDestination() {
      Column() {
        if (this.showCompletionMessage) {
          Text('All rituals completed! 🎉')
            .fontSize(this.baseSize() * 0.08)
            .fontColor(Color.Green)
            .textAlign(TextAlign.Center)
          Button('Back')
            .margin({ top: 20 })
            .onClick(() => this.pageStack.pop())
        } else if (this.currentRitual) {
          Text(this.currentRitual.title)
            .fontSize(this.baseSize() * 0.07)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .margin({ bottom: 10 })

          if (this.currentRitual.type === RitualType.BREATHING) {
            this.renderBreathingUI();
          } else {
            Text(this.currentRitual.time)
              .fontSize(this.baseSize() * 0.05)
              .fontColor('#CCC')
              .margin({ bottom: 30 })

            Row() {
              Button('Back')
                .onClick(() => this.pageStack.pop())
                .backgroundColor(Color.Transparent)
                .border({ width: 1, color: Color.White })
                .width('40%')

              Button('Done')
                .onClick(() => this.completeCurrentRitual())
                .backgroundColor(Color.Green)
                .width('40%')
            }
            .width('90%')
            .justifyContent(FlexAlign.SpaceEvenly)
          }
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Black)
      .justifyContent(FlexAlign.Center)
    }
    .onReady((ctx: NavDestinationContext) => {
      this.pageStack = ctx.pathStack;
      this.periodId = ctx.pathInfo.param as number;
      this.loadNextRitual();
    })
    .hideBackButton(true)
  }
}
