import { BloomLevel } from '../model/Assessment';

@Component
export struct RadarChart {
  @Prop levelScores: Map<BloomLevel, number> = new Map();
  private levels: BloomLevel[] = ['remember', 'understand', 'apply', 'analyze', 'evaluate', 'create'];
  private levelNames: string[] = ['记忆', '理解', '应用', '分析', '评价', '创造'];

  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  build() {
    Canvas(this.context)
      .width('100%')
      .height('100%')
      .onReady(() => {
        this.drawRadarChart();
      })
  }

  private drawRadarChart(): void {
    const width = this.context.width;
    const height = this.context.height;
    const centerX = width / 2;
    const centerY = height / 2;
    const maxRadius = Math.min(width, height) / 2 - 40;
    const numLevels = this.levels.length;
    const angleStep = (2 * Math.PI) / numLevels;

    // Clear
    this.context.clearRect(0, 0, width, height);

    // Draw background circles
    this.context.strokeStyle = '#E0E0E0';
    this.context.lineWidth = 1;
    for (let i = 1; i <= 5; i++) {
      const radius = (maxRadius * i) / 5;
      this.context.beginPath();
      for (let j = 0; j <= numLevels; j++) {
        const angle = j * angleStep - Math.PI / 2;
        const x = centerX + radius * Math.cos(angle);
        const y = centerY + radius * Math.sin(angle);
        if (j === 0) {
          this.context.moveTo(x, y);
        } else {
          this.context.lineTo(x, y);
        }
      }
      this.context.stroke();
    }

    // Draw axes
    for (let i = 0; i < numLevels; i++) {
      const angle = i * angleStep - Math.PI / 2;
      const x = centerX + maxRadius * Math.cos(angle);
      const y = centerY + maxRadius * Math.sin(angle);
      
      this.context.beginPath();
      this.context.moveTo(centerX, centerY);
      this.context.lineTo(x, y);
      this.context.stroke();

      // Draw labels
      const labelX = centerX + (maxRadius + 20) * Math.cos(angle);
      const labelY = centerY + (maxRadius + 20) * Math.sin(angle);
      
      this.context.fillStyle = '#666666';
      this.context.font = '12px sans-serif';
      this.context.textAlign = 'center';
      this.context.textBaseline = 'middle';
      this.context.fillText(this.levelNames[i], labelX, labelY);
    }

    // Draw data polygon
    this.context.fillStyle = 'rgba(0, 102, 204, 0.3)';
    this.context.strokeStyle = '#0066CC';
    this.context.lineWidth = 2;
    
    this.context.beginPath();
    for (let i = 0; i <= numLevels; i++) {
      const idx = i % numLevels;
      const angle = idx * angleStep - Math.PI / 2;
      const score = this.levelScores.get(this.levels[idx]) || 0;
      const radius = (maxRadius * score) / 100;
      
      const x = centerX + radius * Math.cos(angle);
      const y = centerY + radius * Math.sin(angle);
      
      if (i === 0) {
        this.context.moveTo(x, y);
      } else {
        this.context.lineTo(x, y);
      }
    }
    this.context.closePath();
    this.context.fill();
    this.context.stroke();

    // Draw data points
    for (let i = 0; i < numLevels; i++) {
      const angle = i * angleStep - Math.PI / 2;
      const score = this.levelScores.get(this.levels[i]) || 0;
      const radius = (maxRadius * score) / 100;
      
      const x = centerX + radius * Math.cos(angle);
      const y = centerY + radius * Math.sin(angle);
      
      this.context.fillStyle = '#0066CC';
      this.context.beginPath();
      this.context.arc(x, y, 4, 0, 2 * Math.PI);
      this.context.fill();
    }
  }
}
