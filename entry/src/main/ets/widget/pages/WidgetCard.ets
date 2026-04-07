@Entry
@Component
struct WidgetCard {
  /*
   * The title of the widget.
   */
  readonly TITLE: string = 'Habit Progress';

  /*
   * The background color of the card.
   */
  readonly BG_COLOR: string = '#000000';

  /*
   * The action type.
   */
  readonly ACTION_TYPE: string = 'router';

  /*
   * The ability name to be jumped to.
   */
  readonly ABILITY_NAME: string = 'EntryAbility';

  /*
   * The message of the card.
   */
  @LocalStorageProp('progress') progress: string = '0%';
  @LocalStorageProp('nextRitual') nextRitual: string = 'Start Daily Rituals';

  build() {
    Stack() {
      Column() {
        Text(this.TITLE)
          .fontSize(12)
          .fontColor('#AAA')
          .margin({ bottom: 4 })

        Text(this.nextRitual)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row() {
          Progress({ value: parseInt(this.progress), total: 100, type: ProgressType.Capsule })
            .width('70%')
            .height(8)
            .color('#4ea5d7')
            .backgroundColor('#222')

          Text(this.progress)
            .fontSize(12)
            .fontColor(Color.White)
            .margin({ left: 8 })
        }
        .margin({ top: 8 })
      }
      .width('100%')
      .padding(12)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.BG_COLOR)
    .onClick(() => {
      postCardAction(this, {
        "action": this.ACTION_TYPE,
        "abilityName": this.ABILITY_NAME,
        "params": {
          "message": "router from widget"
        }
      });
    })
  }
}
