import webview from '@ohos.web.webview';
import { KnowledgeNode } from '../model/KnowledgeNode';
import { KnowledgeEdge } from '../model/KnowledgeEdge';
import { ConfigurationConstant } from '@kit.AbilityKit';
import common from '@ohos.app.ability.common';

class GraphBridgeObj {
  onNodeClick: (nodeId: string) => void = (_nodeId: string) => {};
}

@Component
export struct KnowledgeGraphWeb {
  @Prop nodes: KnowledgeNode[] = [];
  @Prop edges: KnowledgeEdge[] = [];
  @Prop @Watch('onVersionChange') version: number = 0;
  onNodeClick?: (nodeId: string) => void;

  private webController: webview.WebviewController = new webview.WebviewController();
  private graphBridge: GraphBridgeObj = new GraphBridgeObj();
  private pageLoaded: boolean = false;

  aboutToAppear(): void {
    this.graphBridge.onNodeClick = (nodeId: string) => {
      if (this.onNodeClick) {
        this.onNodeClick(nodeId);
      }
    };
  }

  onVersionChange(): void {
    if (this.pageLoaded) {
      this.clearAndReinject();
    }
  }

  private isDarkMode(): boolean {
    try {
      const config = getContext(this) as common.UIAbilityContext;
      return config.config.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
    } catch (_e) {
      return false;
    }
  }

  build() {
    Web({ src: $rawfile('knowledge_graph.html'), controller: this.webController })
      .width('100%')
      .height('100%')
      .javaScriptAccess(true)
      .domStorageAccess(true)
      .javaScriptProxy({
        object: this.graphBridge,
        name: 'graphBridge',
        methodList: ['onNodeClick'],
        controller: this.webController
      })
      .onPageEnd(() => {
        this.pageLoaded = true;
        this.webController.runJavaScript(`applyTheme(${this.isDarkMode()})`);
        if (this.nodes.length > 0) {
          this.injectGraphData();
        }
      })
  }

  injectGraphData(): void {
    if (!this.pageLoaded) return;
    this.webController.runJavaScript(`applyTheme(${this.isDarkMode()})`);
    const jsNodes = this.nodes.map(n => {
      return `{id:"${n.id}",label:"${this.escapeStr(n.label)}",type:"${n.type}",content:"${this.escapeStr(n.content || '')}"}`;
    });
    const jsEdges = this.edges.map(e => {
      return `{id:"${e.id}",from:"${e.fromNodeId}",to:"${e.toNodeId}",type:"${e.type}"}`;
    });
    const js = `initGraph({nodes:[${jsNodes.join(',')}],edges:[${jsEdges.join(',')}]})`;
    this.webController.runJavaScript(js);
  }

  clearAndReinject(): void {
    if (!this.pageLoaded) return;
    this.webController.runJavaScript('clearGraph()');
    this.injectGraphData();
  }

  private escapeStr(s: string): string {
    return s.replace(/\\/g, '\\\\').replace(/"/g, '\\"').replace(/\n/g, '\\n').replace(/\r/g, '');
  }
}

