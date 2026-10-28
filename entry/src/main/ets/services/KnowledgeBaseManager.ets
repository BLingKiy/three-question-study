import { RDBService } from './RDBService';
import { FileService, MaterialInfo } from './FileService';
import { KnowledgeNode } from '../model/KnowledgeNode';
import { KnowledgeEdge } from '../model/KnowledgeEdge';

export interface KnowledgeGraphData {
  nodes: KnowledgeNode[];
  edges: KnowledgeEdge[];
}

export interface NodeDetailsData {
  node: KnowledgeNode | null;
  incomingEdges: KnowledgeEdge[];
  outgoingEdges: KnowledgeEdge[];
}

class KnowledgeGraphDataImpl implements KnowledgeGraphData {
  nodes: KnowledgeNode[] = [];
  edges: KnowledgeEdge[] = [];
}

class NodeDetailsDataImpl implements NodeDetailsData {
  node: KnowledgeNode | null = null;
  incomingEdges: KnowledgeEdge[] = [];
  outgoingEdges: KnowledgeEdge[] = [];
}

export class KnowledgeBaseManager {
  private rdbService: RDBService;
  private fileService: FileService;

  constructor(rdbService: RDBService, fileService: FileService) {
    this.rdbService = rdbService;
    this.fileService = fileService;
  }

  async getKnowledgeGraph(courseId: string): Promise<KnowledgeGraphData> {
    const nodes = await this.rdbService.queryKnowledgeNodes(courseId);
    const edges = await this.rdbService.queryKnowledgeEdges(courseId);
    
    const result = new KnowledgeGraphDataImpl();
    result.nodes = nodes;
    result.edges = edges;
    return result;
  }

  async getCompositeKnowledgeBase(courseId: string): Promise<string> {
    const graph = await this.getKnowledgeGraph(courseId);
    const nodes = graph.nodes;
    const materials = await this.fileService.getMaterials(courseId);
    
    let knowledgeBase = '';
    
    knowledgeBase += '## 知识图谱\n\n';
    for (const node of nodes) {
      knowledgeBase += `### ${node.label} (${node.type})\n`;
      if (node.content) {
        knowledgeBase += `${node.content}\n\n`;
      }
    }
    
    if (materials.length > 0) {
      knowledgeBase += '\n## 补充材料\n\n';
      for (const material of materials) {
        knowledgeBase += `### ${material.fileName}\n`;
        knowledgeBase += `${material.content}\n\n`;
      }
    }
    
    return knowledgeBase;
  }

  async uploadMaterial(courseId: string, fileName: string, content: ArrayBuffer): Promise<MaterialInfo> {
    return await this.fileService.saveMaterial(courseId, fileName, content);
  }

  async getMaterials(courseId: string): Promise<MaterialInfo[]> {
    return await this.fileService.getMaterials(courseId);
  }

  async deleteMaterial(courseId: string, materialId: string): Promise<void> {
    await this.fileService.deleteMaterial(courseId, materialId);
  }

  async searchNodes(courseId: string, query: string): Promise<KnowledgeNode[]> {
    const nodes = await this.rdbService.queryKnowledgeNodes(courseId);
    const lowerQuery = query.toLowerCase();
    
    return nodes.filter(node => 
      node.label.toLowerCase().includes(lowerQuery) ||
      (node.content && node.content.toLowerCase().includes(lowerQuery))
    );
  }

  async getNodeDetails(nodeId: string): Promise<NodeDetailsData> {
    const node = await this.rdbService.queryKnowledgeNodeById(nodeId);
    const allEdges = await this.rdbService.queryEdgesByNodeId(nodeId);
    
    const incomingEdges: KnowledgeEdge[] = [];
    const outgoingEdges: KnowledgeEdge[] = [];
    
    for (const edge of allEdges) {
      if (edge.toNodeId === nodeId) {
        incomingEdges.push(edge);
      }
      if (edge.fromNodeId === nodeId) {
        outgoingEdges.push(edge);
      }
    }
    
    const result = new NodeDetailsDataImpl();
    result.node = node;
    result.incomingEdges = incomingEdges;
    result.outgoingEdges = outgoingEdges;
    return result;
  }

  async getControversyNodes(courseId: string): Promise<KnowledgeNode[]> {
    const nodes = await this.rdbService.queryKnowledgeNodes(courseId);
    return nodes.filter(n => n.type === 'controversy');
  }

  async getConceptNodes(courseId: string): Promise<KnowledgeNode[]> {
    const nodes = await this.rdbService.queryKnowledgeNodes(courseId);
    return nodes.filter(n => n.type === 'concept');
  }

  async getEvidenceNodes(courseId: string): Promise<KnowledgeNode[]> {
    const nodes = await this.rdbService.queryKnowledgeNodes(courseId);
    return nodes.filter(n => n.type === 'evidence');
  }
}
