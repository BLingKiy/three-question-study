import webview from '@ohos.web.webview';
import { DimensionScores } from '../model/Assessment';
import { ConfigurationConstant } from '@kit.AbilityKit';
import common from '@ohos.app.ability.common';

@Component
export struct RadarChartWeb {
  @Prop dimensions: DimensionScores = { conceptUnderstanding: 0, criticalThinking: 0, practicalTransfer: 0 };

  private webController: webview.WebviewController = new webview.WebviewController();
  private pageLoaded: boolean = false;

  private isDarkMode(): boolean {
    try {
      const config = getContext(this) as common.UIAbilityContext;
      return config.config.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
    } catch (_e) {
      return false;
    }
  }

  build() {
    Web({ src: $rawfile('radar_chart.html'), controller: this.webController })
      .width('100%')
      .height('100%')
      .javaScriptAccess(true)
      .domStorageAccess(true)
      .onPageEnd(() => {
        this.pageLoaded = true;
        this.webController.runJavaScript(`applyTheme(${this.isDarkMode()})`);
        this.injectRadarData();
      })
  }

  aboutToUpdate(): void {
    if (this.pageLoaded) {
      this.webController.runJavaScript(`applyTheme(${this.isDarkMode()})`);
      this.injectRadarData();
    }
  }

  injectRadarData(): void {
    if (!this.pageLoaded) return;
    const cu = this.dimensions.conceptUnderstanding;
    const ct = this.dimensions.criticalThinking;
    const pt = this.dimensions.practicalTransfer;
    const js = `renderRadar(${cu},${ct},${pt})`;
    this.webController.runJavaScript(js);
  }
}
