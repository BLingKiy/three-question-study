import { RDBService } from './RDBService';
import { Assessment, FollowUp, AssessmentReport, DimensionScores, DimensionAnalysis, ErrorTrace } from '../model/Assessment';
import { Course } from '../model/Course';
import fileFs from '@ohos.file.fs';
import filePicker from '@ohos.file.picker';
import util from '@ohos.util';

export type ExportType = 'report' | 'errorCollection' | 'dialogRecords';
export type ExportFormat = 'txt' | 'json' | 'markdown';

class DialogRecordEntry {
  question: string = '';
  followUps: FollowUp[] = [];
}

class ErrorEntry {
  id: string = '';
  question: string = '';
  questionType: string = '';
  bloomLevel: string = '';
  userAnswer: string = '';
  correctAnswer: string = '';
  referenceAnswer: string = '';
}

export class ExportService {
  private rdbService: RDBService;

  constructor(rdbService: RDBService) {
    this.rdbService = rdbService;
  }

  async exportData(
    context: Context,
    courseId: string,
    type: ExportType,
    format: ExportFormat
  ): Promise<string> {
    let content = '';
    let fileName = '';

    if (type === 'report') {
      const report = await this.rdbService.getAssessmentReportByCourseId(courseId);
      if (!report) {
        throw new Error('请先生成测评报告');
      }
      content = this.formatReport(report, format);
      fileName = `learning_report_${courseId.substring(0, 8)}`;
    } else if (type === 'errorCollection') {
      const assessments = await this.rdbService.queryAssessments(courseId);
      const errors = assessments.filter(a => a.userAnswer && a.userAnswer.length > 0 && !a.isCorrect);
      content = this.formatErrorCollection(errors, format);
      fileName = `error_collection_${courseId.substring(0, 8)}`;
    } else {
      const assessments = await this.rdbService.queryAssessments(courseId);
      content = await this.formatDialogRecords(assessments, format);
      fileName = `dialog_records_${courseId.substring(0, 8)}`;
    }

    const ext = format === 'txt' ? '.txt' : format === 'json' ? '.json' : '.md';
    fileName += ext;

    return await this.saveExportFile(context, content, fileName);
  }

  private formatReport(report: AssessmentReport, format: ExportFormat): string {
    if (format === 'json') {
      return JSON.stringify({
        courseId: report.courseId,
        dimensions: report.dimensions,
        overallSuggestion: report.overallSuggestion,
        dimensionAnalysis: report.dimensionAnalysis,
        errorTraces: report.errorTraces,
        createdAt: report.createdAt
      }, null, 2);
    }

    if (format === 'markdown') {
      let md = '# 测评报告\n\n';
      md += '## 能力维度评分\n\n';
      md += `| 维度 | 分数 |\n| --- | --- |\n`;
      md += `| 概念理解 | ${report.dimensions.conceptUnderstanding} |\n`;
      md += `| 批判思维 | ${report.dimensions.criticalThinking} |\n`;
      md += `| 实践迁移 | ${report.dimensions.practicalTransfer} |\n\n`;
      md += '## 整体复习建议\n\n';
      md += `${report.overallSuggestion}\n\n`;
      md += '## 维度分析\n\n';
      md += `### 概念理解\n\n${report.dimensionAnalysis.conceptUnderstanding}\n\n`;
      md += `### 批判思维\n\n${report.dimensionAnalysis.criticalThinking}\n\n`;
      md += `### 实践迁移\n\n${report.dimensionAnalysis.practicalTransfer}\n\n`;
      md += '## 错题溯源\n\n';
      if (report.errorTraces.length === 0) {
        md += '全部回答正确，无需溯源复习\n';
      } else {
        for (const trace of report.errorTraces) {
          md += `- **${trace.knowledgeNodeLabel}**：${trace.traceExplanation}\n`;
        }
      }
      return md;
    }

    let txt = '=== 测评报告 ===\n\n';
    txt += '【能力维度评分】\n';
    txt += `  概念理解：${report.dimensions.conceptUnderstanding}\n`;
    txt += `  批判思维：${report.dimensions.criticalThinking}\n`;
    txt += `  实践迁移：${report.dimensions.practicalTransfer}\n\n`;
    txt += '【整体复习建议】\n';
    txt += `${report.overallSuggestion}\n\n`;
    txt += '【维度分析】\n';
    txt += `  概念理解：${report.dimensionAnalysis.conceptUnderstanding}\n`;
    txt += `  批判思维：${report.dimensionAnalysis.criticalThinking}\n`;
    txt += `  实践迁移：${report.dimensionAnalysis.practicalTransfer}\n\n`;
    txt += '【错题溯源】\n';
    if (report.errorTraces.length === 0) {
      txt += '  全部回答正确，无需溯源复习\n';
    } else {
      for (const trace of report.errorTraces) {
        txt += `  - ${trace.knowledgeNodeLabel}：${trace.traceExplanation}\n`;
      }
    }
    return txt;
  }

  private formatErrorCollection(errors: Assessment[], format: ExportFormat): string {
    if (format === 'json') {
      const data: ErrorEntry[] = [];
      for (const a of errors) {
        const entry = new ErrorEntry();
        entry.id = a.id;
        entry.question = a.question;
        entry.questionType = a.questionType;
        entry.bloomLevel = a.bloomLevel;
        entry.userAnswer = a.userAnswer || '';
        entry.correctAnswer = a.correctAnswer || '';
        entry.referenceAnswer = a.answer || '';
        data.push(entry);
      }
      return JSON.stringify({ errorCount: errors.length, errors: data }, null, 2);
    }

    if (format === 'markdown') {
      let md = '# 错题集\n\n';
      if (errors.length === 0) {
        md += '全部回答正确，无错题\n';
        return md;
      }
      md += `共 ${errors.length} 道错题\n\n`;
      for (let i = 0; i < errors.length; i++) {
        const a = errors[i];
        md += `## ${i + 1}. ${a.question}\n\n`;
        md += `- 题型：${a.questionType}\n`;
        md += `- 布鲁姆层次：${a.bloomLevel}\n`;
        md += `- 你的答案：${a.userAnswer || '未作答'}\n`;
        md += `- 正确答案：${a.correctAnswer}\n`;
        if (a.answer) {
          md += `- 参考答案：${a.answer}\n`;
        }
        md += '\n';
      }
      return md;
    }

    let txt = '=== 错题集 ===\n\n';
    if (errors.length === 0) {
      txt += '全部回答正确，无错题\n';
      return txt;
    }
    txt += `共 ${errors.length} 道错题\n\n`;
    for (let i = 0; i < errors.length; i++) {
      const a = errors[i];
      txt += `${i + 1}. ${a.question}\n`;
      txt += `   题型：${a.questionType}\n`;
      txt += `   布鲁姆层次：${a.bloomLevel}\n`;
      txt += `   你的答案：${a.userAnswer || '未作答'}\n`;
      txt += `   正确答案：${a.correctAnswer}\n`;
      if (a.answer) {
        txt += `   参考答案：${a.answer}\n`;
      }
      txt += '\n';
    }
    return txt;
  }

  private async formatDialogRecords(assessments: Assessment[], format: ExportFormat): Promise<string> {
    const allRecords: DialogRecordEntry[] = [];
    for (const a of assessments) {
      const followUps = await this.rdbService.queryFollowUpsByAssessmentId(a.id);
      if (followUps.length > 0) {
        const entry = new DialogRecordEntry();
        entry.question = a.question;
        entry.followUps = followUps;
        allRecords.push(entry);
      }
    }

    if (format === 'json') {
      return JSON.stringify({ recordCount: allRecords.length, records: allRecords }, null, 2);
    }

    if (format === 'markdown') {
      let md = '# 对话原始记录\n\n';
      if (allRecords.length === 0) {
        md += '暂无对话记录\n';
        return md;
      }
      for (let i = 0; i < allRecords.length; i++) {
        const r = allRecords[i];
        md += `## 题目 ${i + 1}：${r.question}\n\n`;
        for (const f of r.followUps) {
          const label = f.role === 'user' ? '**用户**' : '**AI**';
          md += `${label}：${f.content}\n\n`;
        }
      }
      return md;
    }

    let txt = '=== 对话原始记录 ===\n\n';
    if (allRecords.length === 0) {
      txt += '暂无对话记录\n';
      return txt;
    }
    for (let i = 0; i < allRecords.length; i++) {
      const r = allRecords[i];
      txt += `题目 ${i + 1}：${r.question}\n`;
      for (const f of r.followUps) {
        const label = f.role === 'user' ? '用户' : 'AI';
        txt += `  ${label}：${f.content}\n`;
      }
      txt += '\n';
    }
    return txt;
  }

  private async saveExportFile(context: Context, content: string, fileName: string): Promise<string> {
    const tempFilePath = `${context.cacheDir}/${fileName}`;
    const file = fileFs.openSync(tempFilePath, fileFs.OpenMode.WRITE_ONLY | fileFs.OpenMode.CREATE | fileFs.OpenMode.TRUNC);
    const encoder = new util.TextEncoder();
    const buffer = encoder.encodeInto(content);
    fileFs.writeSync(file.fd, buffer.buffer);
    fileFs.closeSync(file);

    try {
      const documentViewPicker = new filePicker.DocumentViewPicker();
      const documentSaveOptions = new filePicker.DocumentSaveOptions();
      documentSaveOptions.newFileNames = [fileName];
      const uris = await documentViewPicker.save(documentSaveOptions);
      if (uris && uris.length > 0) {
        const srcFile = fileFs.openSync(tempFilePath, fileFs.OpenMode.READ_ONLY);
        const stat = fileFs.statSync(tempFilePath);
        const buf = new ArrayBuffer(stat.size);
        fileFs.readSync(srcFile.fd, buf);
        fileFs.closeSync(srcFile);
        const destFile = fileFs.openSync(uris[0], fileFs.OpenMode.WRITE_ONLY | fileFs.OpenMode.TRUNC);
        fileFs.writeSync(destFile.fd, buf);
        fileFs.closeSync(destFile);
        return uris[0];
      }
    } catch (e) {
      console.warn('[ExportService] DocumentViewPicker save failed:', e);
    }

    return tempFilePath;
  }
}