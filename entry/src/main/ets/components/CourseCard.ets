import { Course } from '../model/Course';

@Component
export struct CourseCard {
  @Prop course: Course | null = null;
  @Prop progress: number = 0;
  @Prop isRetrying: boolean = false;
  onCardClick?: (course: Course) => void;
  onDeleteClick?: (course: Course) => void;
  onRetryQ1Click?: (course: Course) => void;
  onRetryQ2Click?: (course: Course) => void;
  onArchiveClick?: (course: Course) => void;
  onUnarchiveClick?: (course: Course) => void;
  onCompleteClick?: (course: Course) => void;
  onUncompleteClick?: (course: Course) => void;

  build() {
    Column() {
      Row() {
        Text(this.course?.name || '未命名课程')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)

        Text(this.getStatusText())
          .fontSize(12)
          .fontColor(Color.White)
          .backgroundColor(this.getStatusColor())
          .borderRadius(4)
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ bottom: 12 })

      Text(this.course?.question || '')
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .margin({ bottom: 16 })

      Column() {
        Row() {
          Text('学习进度')
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))

          Text(`${this.progress}%`)
            .fontSize(12)
            .fontColor($r('app.color.tech_blue_primary'))
            .fontWeight(FontWeight.Bold)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({ bottom: 4 })

        Progress({ value: this.progress, total: 100, type: ProgressType.Linear })
          .width('100%')
          .height(6)
          .color($r('app.color.tech_blue_primary'))
      }
      .width('100%')

      if (this.course && !this.course.mentalModelGenerated) {
        Button(this.isRetrying ? '重试中...' : '重试知识图谱')
          .width('100%')
          .height(32)
          .fontSize(12)
          .backgroundColor($r('app.color.warning_color'))
          .margin({ top: 8 })
          .enabled(!this.isRetrying)
          .onClick(() => {
            if (this.course && this.onRetryQ1Click) {
              this.onRetryQ1Click(this.course);
            }
          })
      }

      if (this.course && this.course.mentalModelGenerated && !this.course.controversyGenerated) {
        Button(this.isRetrying ? '重试中...' : '重试争议分析')
          .width('100%')
          .height(32)
          .fontSize(12)
          .backgroundColor($r('app.color.warning_color'))
          .margin({ top: 8 })
          .enabled(!this.isRetrying)
          .onClick(() => {
            if (this.course && this.onRetryQ2Click) {
              this.onRetryQ2Click(this.course);
            }
          })
      }

      Row() {
        Text(this.formatDate(this.course?.createdAt || 0))
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))

        Blank()

        Image($r('app.media.ic_more'))
          .width(20)
          .height(20)
          .fillColor($r('app.color.text_secondary'))
          .bindMenu(this.getMenuItems())
      }
      .width('100%')
      .margin({ top: 12 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(12)
    .shadow({ radius: 8, color: '#1A000000', offsetX: 0, offsetY: 2 })
    .onClick(() => {
      if (this.course && this.onCardClick) {
        this.onCardClick(this.course);
      }
    })
  }

  private getMenuItems(): MenuElement[] {
    if (!this.course) return [];
    const items: MenuElement[] = [];
    const status = this.course.status;

    if (status === 'archived') {
      items.push({
        value: '取消归档',
        action: () => {
          if (this.course && this.onUnarchiveClick) {
            this.onUnarchiveClick(this.course);
          }
        }
      });
    } else {
      if (status === 'completed') {
        items.push({
          value: '取消完成',
          action: () => {
            if (this.course && this.onUncompleteClick) {
              this.onUncompleteClick(this.course);
            }
          }
        });
      }
      items.push({
        value: '归档',
        action: () => {
          if (this.course && this.onArchiveClick) {
            this.onArchiveClick(this.course);
          }
        }
      });
    }

    items.push({
      value: '删除',
      action: () => {
        if (!this.course) return;
        const courseName = this.course.name;
        AlertDialog.show({
          title: '删除课程',
          message: `确定删除课程「${courseName}」？此操作不可恢复。`,
          primaryButton: {
            value: '取消',
            action: () => {}
          },
          secondaryButton: {
            value: '确定',
            action: () => {
              if (this.course && this.onDeleteClick) {
                this.onDeleteClick(this.course);
              }
            }
          }
        });
      }
    });

    return items;
  }

  private getStatusText(): string {
    switch (this.course?.status) {
      case 'created':
        return '创建中';
      case 'active':
        return '学习中';
      case 'completed':
        return '已完成';
      case 'archived':
        return '已归档';
      default:
        return '未知';
    }
  }

  private getStatusColor(): ResourceColor {
    switch (this.course?.status) {
      case 'created':
        return $r('app.color.warning_color');
      case 'active':
        return $r('app.color.tech_blue_primary');
      case 'completed':
        return $r('app.color.success_color');
      case 'archived':
        return $r('app.color.text_secondary');
      default:
        return $r('app.color.text_secondary');
    }
  }

  private formatDate(timestamp: number): string {
    if (!timestamp) return '';
    const date = new Date(timestamp);
    return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
  }
}
