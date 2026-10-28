import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import preferences from '@ohos.data.preferences';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.restoreColorMode();
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  private async restoreColorMode(): Promise<void> {
    try {
      const prefs = await preferences.getPreferences(this.context, 'ThreeQuestionStudyPrefs');
      const colorMode = await prefs.get('color_mode', ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET) as number;
      this.context.getApplicationContext().setColorMode(colorMode);
    } catch (err) {
      try {
        this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
      } catch (e) {
        hilog.error(DOMAIN, 'testTag', 'Failed to set default colorMode. Cause: %{public}s', JSON.stringify(e));
      }
    }
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/MainPage', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}
