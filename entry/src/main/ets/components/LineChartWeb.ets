import webview from '@ohos.web.webview';
import { ConfigurationConstant } from '@kit.AbilityKit';
import common from '@ohos.app.ability.common';

@Component
export struct LineChartWeb {
  @Prop dates: string[] = [];
  @Prop durations: number[] = [];

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
    Web({ src: $rawfile('line_chart.html'), controller: this.webController })
      .width('100%')
      .height('100%')
      .javaScriptAccess(true)
      .domStorageAccess(true)
      .onPageEnd(() => {
        this.pageLoaded = true;
        this.webController.runJavaScript(`applyTheme(${this.isDarkMode()})`);
        this.injectData();
      })
  }

  aboutToUpdate(): void {
    if (this.pageLoaded) {
      this.webController.runJavaScript(`applyTheme(${this.isDarkMode()})`);
      this.injectData();
    }
  }

  injectData(): void {
    if (!this.pageLoaded) return;
    const datesJson = JSON.stringify(this.dates);
    const durationsJson = JSON.stringify(this.durations);
    const js = `renderLineChart(${datesJson},${durationsJson})`;
    this.webController.runJavaScript(js);
  }
}
