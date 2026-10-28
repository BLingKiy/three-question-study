import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import util from '@ohos.util';

export interface MaterialInfo {
  id: string;
  courseId: string;
  fileName: string;
  fileType: 'pdf' | 'word' | 'markdown' | 'text';
  fileSize: number;
  content: string;
  createdAt: number;
}

class MaterialInfoImpl implements MaterialInfo {
  id: string = '';
  courseId: string = '';
  fileName: string = '';
  fileType: 'pdf' | 'word' | 'markdown' | 'text' = 'text';
  fileSize: number = 0;
  content: string = '';
  createdAt: number = 0;
}

export class FileService {
  private context: common.Context;

  constructor(context: common.Context) {
    this.context = context;
  }

  private getMaterialsDir(): string {
    return `${this.context.filesDir}/materials`;
  }

  async initialize(): Promise<void> {
    try {
      const materialsDir = this.getMaterialsDir();
      if (!fs.accessSync(materialsDir)) {
        fs.mkdirSync(materialsDir);
      }
      console.info('[FileService] File service initialized successfully');
    } catch (err) {
      console.error('[FileService] Failed to initialize:', err);
      throw new Error((err as Error).message);
    }
  }

  async saveMaterial(courseId: string, fileName: string, content: ArrayBuffer): Promise<MaterialInfo> {
    const materialsDir = this.getMaterialsDir();
    const courseDir = `${materialsDir}/${courseId}`;
    
    if (!fs.accessSync(courseDir)) {
      fs.mkdirSync(courseDir);
    }

    const materialId = `${courseId}_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const filePath = `${courseDir}/${materialId}_${fileName}`;
    const file = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
    fs.writeSync(file.fd, content);
    fs.closeSync(file);

    const fileType = this.getFileType(fileName);
    const textContent = await this.extractText(filePath, fileType);

    const info = new MaterialInfoImpl();
    info.id = materialId;
    info.courseId = courseId;
    info.fileName = fileName;
    info.fileType = fileType;
    info.fileSize = content.byteLength;
    info.content = textContent;
    info.createdAt = Date.now();
    return info;
  }

  private getFileType(fileName: string): 'pdf' | 'word' | 'markdown' | 'text' {
    const ext = fileName.split('.').pop()?.toLowerCase() || '';
    switch (ext) {
      case 'pdf':
        return 'pdf';
      case 'doc':
      case 'docx':
        return 'word';
      case 'md':
      case 'markdown':
        return 'markdown';
      default:
        return 'text';
    }
  }

  private async extractText(filePath: string, fileType: 'pdf' | 'word' | 'markdown' | 'text'): Promise<string> {
    try {
      if (fileType === 'text' || fileType === 'markdown') {
        const file = fs.openSync(filePath, fs.OpenMode.READ_ONLY);
        const stat = fs.statSync(filePath);
        const buffer = new ArrayBuffer(stat.size);
        fs.readSync(file.fd, buffer);
        fs.closeSync(file);
        
        const decoder = new util.TextDecoder('utf-8');
        return decoder.decodeToString(new Uint8Array(buffer));
      }

      if (fileType === 'pdf') {
        return '[PDF内容需要解析]';
      }
      if (fileType === 'word') {
        return '[Word内容需要解析]';
      }

      return '';
    } catch (err) {
      console.error('[FileService] Failed to extract text:', err);
      return '';
    }
  }

  async getMaterials(courseId: string): Promise<MaterialInfo[]> {
    const materialsDir = this.getMaterialsDir();
    const courseDir = `${materialsDir}/${courseId}`;
    
    if (!fs.accessSync(courseDir)) {
      return [];
    }
    
    const materials: MaterialInfo[] = [];
    try {
      const listFile = fs.listFileSync(courseDir);
      for (const fileName of listFile) {
        const filePath = `${courseDir}/${fileName}`;
        const stat = fs.statSync(filePath);
        if (stat.isDirectory()) continue;
        
        const parts = fileName.split('_');
        const materialId = parts.length >= 3 ? parts[0] + '_' + parts[1] + '_' + parts[2] : fileName;
        const originalName = parts.length >= 4 ? parts.slice(3).join('_') : fileName;
        const fileType = this.getFileType(originalName);
        
        const info = new MaterialInfoImpl();
        info.id = materialId;
        info.courseId = courseId;
        info.fileName = originalName;
        info.fileType = fileType;
        info.fileSize = stat.size;
        info.content = '';
        info.createdAt = stat.mtime * 1000;
        materials.push(info);
      }
    } catch (err) {
      console.error('[FileService] Failed to list materials:', err);
    }
    
    return materials;
  }

  async deleteMaterial(courseId: string, materialId: string): Promise<void> {
    const materialsDir = this.getMaterialsDir();
    const courseDir = `${materialsDir}/${courseId}`;
    
    if (!fs.accessSync(courseDir)) {
      return;
    }

    try {
      const listFile = fs.listFileSync(courseDir);
      for (const fileName of listFile) {
        if (fileName.startsWith(materialId)) {
          fs.unlinkSync(`${courseDir}/${fileName}`);
          break;
        }
      }
    } catch (err) {
      console.error('[FileService] Failed to delete material:', err);
    }
  }

  async deleteAllMaterials(courseId: string): Promise<void> {
    const materialsDir = this.getMaterialsDir();
    const courseDir = `${materialsDir}/${courseId}`;
    
    if (fs.accessSync(courseDir)) {
      fs.rmdirSync(courseDir);
    }
  }

  async getMaterialContent(materialId: string): Promise<string> {
    return '';
  }
}
