import { KnowledgeNode } from '../model/KnowledgeNode';
import { KnowledgeEdge } from '../model/KnowledgeEdge';

@Component
export struct KnowledgeGraphCanvas {
  @Prop nodes: KnowledgeNode[] = [];
  @Prop edges: KnowledgeEdge[] = [];
  @State graphScale: number = 1.0;
  @State offsetX: number = 0;
  @State offsetY: number = 0;
  onNodeClick?: (node: KnowledgeNode) => void;

  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  build() {
    Stack() {
      Canvas(this.context)
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.tech_blue_light'))
        .onReady(() => {
          this.drawGraph();
        })
        .gesture(
          GestureGroup(GestureMode.Parallel,
            // Pinch to zoom
            PinchGesture({ fingers: 2 })
              .onActionUpdate((event: GestureEvent) => {
                this.graphScale = Math.max(0.5, Math.min(2.0, event.scale));
                this.drawGraph();
              }),
            // Pan
            PanGesture({ fingers: 1, direction: PanDirection.All })
              .onActionUpdate((event: GestureEvent) => {
                this.offsetX += event.offsetX;
                this.offsetY += event.offsetY;
                this.drawGraph();
              })
          )
        )
    }
    .width('100%')
    .height('100%')
  }

  private drawGraph(): void {
    const width = this.context.width;
    const height = this.context.height;
    
    // Clear canvas
    this.context.clearRect(0, 0, width, height);
    
    // Apply transformations
    this.context.save();
    this.context.translate(this.offsetX, this.offsetY);
    this.context.scale(this.graphScale, this.graphScale);

    // Draw edges
    this.context.lineWidth = 2;
    for (const edge of this.edges) {
      const source = this.nodes.find(n => n.id === edge.fromNodeId);
      const target = this.nodes.find(n => n.id === edge.toNodeId);
      
      if (source && target) {
        // Set edge color based on type
        switch (edge.type) {
          case 'supports':
            this.context.strokeStyle = '#4CAF50';
            break;
          case 'opposes':
            this.context.strokeStyle = '#F44336';
            break;
          default:
            this.context.strokeStyle = '#666666';
        }
        
        this.context.beginPath();
        this.context.moveTo(source.position.x, source.position.y);
        this.context.lineTo(target.position.x, target.position.y);
        this.context.stroke();
        
        // Draw arrow
        this.drawArrow(source.position.x, source.position.y, target.position.x, target.position.y);
      }
    }

    // Draw nodes
    for (const node of this.nodes) {
      // Node color based on type
      let nodeColor = '#0066CC';
      switch (node.type) {
        case 'concept':
          nodeColor = '#0066CC';
          break;
        case 'controversy':
          nodeColor = '#FF9800';
          break;
        case 'evidence':
          nodeColor = '#4CAF50';
          break;
      }

      // Draw node circle
      this.context.fillStyle = nodeColor;
      this.context.beginPath();
      this.context.arc(node.position.x, node.position.y, 20, 0, 2 * Math.PI);
      this.context.fill();

      // Draw node label
      this.context.fillStyle = '#333333';
      this.context.font = '12px sans-serif';
      this.context.textAlign = 'center';
      this.context.fillText(node.label, node.position.x, node.position.y + 35);
    }

    this.context.restore();
  }

  private drawArrow(fromX: number, fromY: number, toX: number, toY: number): void {
    const headLength = 10;
    const dx = toX - fromX;
    const dy = toY - fromY;
    const angle = Math.atan2(dy, dx);

    // Adjust arrow position to not overlap with node
    const nodeRadius = 20;
    const adjustedToX = toX - Math.cos(angle) * nodeRadius;
    const adjustedToY = toY - Math.sin(angle) * nodeRadius;

    this.context.beginPath();
    this.context.moveTo(adjustedToX, adjustedToY);
    this.context.lineTo(
      adjustedToX - headLength * Math.cos(angle - Math.PI / 6),
      adjustedToY - headLength * Math.sin(angle - Math.PI / 6)
    );
    this.context.moveTo(adjustedToX, adjustedToY);
    this.context.lineTo(
      adjustedToX - headLength * Math.cos(angle + Math.PI / 6),
      adjustedToY - headLength * Math.sin(angle + Math.PI / 6)
    );
    this.context.stroke();
  }

  // Handle node click
  private handleCanvasClick(x: number, y: number): void {
    const adjustedX = (x - this.offsetX) / this.graphScale;
    const adjustedY = (y - this.offsetY) / this.graphScale;

    for (const node of this.nodes) {
      const dx = adjustedX - node.position.x;
      const dy = adjustedY - node.position.y;
      const distance = Math.sqrt(dx * dx + dy * dy);

      if (distance <= 20 && this.onNodeClick) {
        this.onNodeClick(node);
        break;
      }
    }
  }
}
