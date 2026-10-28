import webview from '@ohos.web.webview';
import { ParsedControversy } from '../services/ResponseParser';

@Component
export struct ControversyLogicChain {
  @Prop controversy: ParsedControversy | null = null;
  @State isExpanded: boolean = false;

  private webController: webview.WebviewController = new webview.WebviewController();

  build() {
    Column() {
      Row() {
        Text('逻辑链图谱')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)

        Text(this.isExpanded ? '收起 ▲' : '展开 ▼')
          .fontSize(12)
          .fontColor($r('app.color.tech_blue_primary'))
      }
      .width('100%')
      .padding({ top: 8, bottom: 8 })
      .onClick(() => {
        this.isExpanded = !this.isExpanded;
        if (this.isExpanded) {
          setTimeout(() => {
            this.injectLogicChainData();
          }, 300);
        }
      })

      if (this.isExpanded) {
        if (this.hasEvidence()) {
          Web({ src: $rawfile('knowledge_graph.html'), controller: this.webController })
            .width('100%')
            .height(200)
            .javaScriptAccess(true)
            .domStorageAccess(true)
            .onPageEnd(() => {
              this.injectLogicChainData();
            })
        } else {
          Text('暂无证据链路')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding(16)
        }
      }
    }
    .width('100%')
  }

  private hasEvidence(): boolean {
    if (!this.controversy) return false;
    return (this.controversy.leftView.evidence.length > 0 || this.controversy.rightView.evidence.length > 0);
  }

  private injectLogicChainData(): void {
    if (!this.controversy) return;

    const c = this.controversy;
    const nodes: string[] = [];
    const edges: string[] = [];

    nodes.push(`{id:"controversy",label:"${this.escapeStr(c.topic)}",type:"controversy",content:"${this.escapeStr(c.topic)}"}`);

    const leftEvidences = c.leftView.evidence || [];
    for (let i = 0; i < leftEvidences.length; i++) {
      const eid = `left_ev_${i}`;
      nodes.push(`{id:"${eid}",label:"${this.escapeStr(leftEvidences[i].substring(0, 20))}",type:"leftEvidence",content:"${this.escapeStr(leftEvidences[i])}"}`);
      edges.push(`{id:"e_lc_${i}",from:"controversy",to:"${eid}",type:"supports"}`);
    }

    const rightEvidences = c.rightView.evidence || [];
    for (let j = 0; j < rightEvidences.length; j++) {
      const eid = `right_ev_${j}`;
      nodes.push(`{id:"${eid}",label:"${this.escapeStr(rightEvidences[j].substring(0, 20))}",type:"rightEvidence",content:"${this.escapeStr(rightEvidences[j])}"}`);
      edges.push(`{id:"e_rc_${j}",from:"controversy",to:"${eid}",type:"opposes"}`);
    }

    if (c.synthesis) {
      nodes.push(`{id:"conclusion",label:"结论",type:"conclusion",content:"${this.escapeStr(c.synthesis)}"}`);
      for (let i = 0; i < leftEvidences.length; i++) {
        edges.push(`{id:"e_lc2_${i}",from:"left_ev_${i}",to:"conclusion",type:"supports"}`);
      }
      for (let j = 0; j < rightEvidences.length; j++) {
        edges.push(`{id:"e_rc2_${j}",from:"right_ev_${j}",to:"conclusion",type:"relates"}`);
      }
    }

    const js = `initGraph({nodes:[${nodes.join(',')}],edges:[${edges.join(',')}]})`;
    this.webController.runJavaScript(js);
  }

  private escapeStr(s: string): string {
    return s.replace(/\\/g, '\\\\').replace(/"/g, '\\"').replace(/\n/g, '\\n').replace(/\r/g, '');
  }
}