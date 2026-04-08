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
  @State isFinished: boolean = false;
  @State screenWidth: number = 0;
  @State screenHeight: number = 0;

  // Breathing state
  @State isBreathing: boolean = false;
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
    if (nextRitual) {
      this.isFinished = false;
      this.currentRitual = {
        id: nextRitual.id,
        title: nextRitual.title,
        time: nextRitual.time,
        color: nextRitual.color,
        type: nextRitual.type,
        targetValue: nextRitual.targetValue
      };
      if (this.currentRitual.type === RitualType.BREATHING) {
        this.breathTimer = this.currentRitual.targetValue;
      }
    } else {
      this.currentRitual = null;
      this.isFinished = true;
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

    this.breathIntervalId = setInterval(() => {
      if (this.breathTimer > 0) {
        this.breathTimer--;
        // Haptic feedback every 4 seconds
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
      }, { usage: 'alarm' });
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
          .width(this.baseSize() * 0.55)
          .height(this.baseSize() * 0.55)
          .style({ strokeWidth: 8 })
          .color(this.currentRitual?.color || Color.Blue)
          .backgroundColor('#111')

        Column() {
          Text(`${this.breathTimer}s`)
            .fontSize(this.baseSize() * 0.12)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
          Text(this.isBreathing ? 'Breathe...' : 'Ready?')
            .fontSize(this.baseSize() * 0.04)
            .fontColor('#AAA')
        }
      }
      .margin({ top: 10, bottom: 20 })

      Button(this.isBreathing ? 'Pause' : 'Start')
        .onClick(() => this.isBreathing ? this.stopBreathing() : this.startBreathing())
        .width('55%')
        .height(this.baseSize() * 0.15)
        .borderRadius(this.baseSize() * 0.08)
        .backgroundColor(this.isBreathing ? '#333' : Color.Green)
    }
  }

  build() {
    NavDestination() {
      Column() {
        if (this.isFinished) {
          Column() {
            Text('Rituals Complete! 🎉')
              .fontSize(this.baseSize() * 0.08)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.Green)
              .textAlign(TextAlign.Center)

            Text('Excellent progress today.')
              .fontSize(this.baseSize() * 0.04)
              .fontColor('#AAA')
              .margin({ top: 8, bottom: 30 })

            Button('Finish')
              .onClick(() => this.pageStack.pop())
              .backgroundColor('#222')
              .width('50%')
              .borderRadius(20)
          }
          .padding(20)
        } else if (this.currentRitual) {
          // Header
          Text(this.currentRitual.title)
            .fontSize(this.baseSize() * 0.07)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .margin({ top: 10 })

          if (this.currentRitual.type === RitualType.BREATHING) {
            this.renderBreathingUI();
          } else {
            Column() {
              Text(this.currentRitual.time)
                .fontSize(this.baseSize() * 0.06)
                .fontColor(this.currentRitual.color)
                .fontWeight(FontWeight.Medium)
                .margin({ top: 40, bottom: 40 })

              Row() {
                Button('Skip')
                  .onClick(() => this.pageStack.pop())
                  .backgroundColor('#222')
                  .width('42%')

                Button('Done')
                  .onClick(() => this.completeCurrentRitual())
                  .backgroundColor(Color.Green)
                  .width('42%')
              }
              .width('95%')
              .justifyContent(FlexAlign.SpaceEvenly)
            }
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
