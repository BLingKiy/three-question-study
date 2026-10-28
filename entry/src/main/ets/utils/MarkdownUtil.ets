export type MdBlockType = 'heading' | 'paragraph' | 'listItem' | 'codeBlock' | 'blank';

export interface MdBlock {
  type: MdBlockType;
  level: number;
  text: string;
  ordered: boolean;
  index: number;
  spans: MdSpan[];
}

export type MdSpanType = 'normal' | 'bold' | 'italic' | 'code';

export interface MdSpan {
  type: MdSpanType;
  text: string;
}

export class MarkdownUtil {
  static parse(md: string): MdBlock[] {
    if (!md) return [];

    const blocks: MdBlock[] = [];
    const codeBlockRegex = /```([\s\S]*?)```/g;
    let processed = md;
    const codeBlocks: string[] = [];

    let cbMatch = codeBlockRegex.exec(processed);
    while (cbMatch !== null) {
      const idx = codeBlocks.length;
      codeBlocks.push(cbMatch[1].trim());
      processed = processed.substring(0, cbMatch.index) + `\n__CB_${idx}__\n` + processed.substring(cbMatch.index + cbMatch[0].length);
      codeBlockRegex.lastIndex = 0;
      cbMatch = codeBlockRegex.exec(processed);
    }

    const lines = processed.split('\n');
    let listIndex = 0;

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];

      const cbLineMatch = line.match(/^__CB_(\d+)__$/);
      if (cbLineMatch) {
        const cbIdx = parseInt(cbLineMatch[1]);
        blocks.push({
          type: 'codeBlock',
          level: 0,
          text: codeBlocks[cbIdx],
          ordered: false,
          index: 0,
          spans: [{ type: 'normal', text: codeBlocks[cbIdx] }]
        });
        continue;
      }

      const h3Match = line.match(/^###\s+(.+)/);
      if (h3Match) {
        blocks.push({
          type: 'heading',
          level: 3,
          text: h3Match[1],
          ordered: false,
          index: 0,
          spans: MarkdownUtil.parseSpans(h3Match[1])
        });
        continue;
      }

      const h4Match = line.match(/^####\s+(.+)/);
      if (h4Match) {
        blocks.push({
          type: 'heading',
          level: 4,
          text: h4Match[1],
          ordered: false,
          index: 0,
          spans: MarkdownUtil.parseSpans(h4Match[1])
        });
        continue;
      }

      const ulMatch = line.match(/^[-*]\s+(.+)/);
      if (ulMatch) {
        listIndex++;
        blocks.push({
          type: 'listItem',
          level: 0,
          text: ulMatch[1],
          ordered: false,
          index: listIndex,
          spans: MarkdownUtil.parseSpans(ulMatch[1])
        });
        continue;
      }

      const olMatch = line.match(/^\d+\.\s+(.+)/);
      if (olMatch) {
        listIndex++;
        blocks.push({
          type: 'listItem',
          level: 0,
          text: olMatch[1],
          ordered: true,
          index: listIndex,
          spans: MarkdownUtil.parseSpans(olMatch[1])
        });
        continue;
      }

      if (line.trim() === '') {
        blocks.push({
          type: 'blank',
          level: 0,
          text: '',
          ordered: false,
          index: 0,
          spans: []
        });
        continue;
      }

      blocks.push({
        type: 'paragraph',
        level: 0,
        text: line,
        ordered: false,
        index: 0,
        spans: MarkdownUtil.parseSpans(line)
      });
    }

    return blocks;
  }

  static parseSpans(text: string): MdSpan[] {
    const spans: MdSpan[] = [];
    const regex = /(\*\*(.+?)\*\*|\*(.+?)\*|`([^`]+)`)/g;
    let lastIndex = 0;
    let match = regex.exec(text);

    while (match !== null) {
      if (match.index > lastIndex) {
        spans.push({ type: 'normal', text: text.substring(lastIndex, match.index) });
      }
      if (match[2]) {
        spans.push({ type: 'bold', text: match[2] });
      } else if (match[4]) {
        spans.push({ type: 'italic', text: match[4] });
      } else if (match[3]) {
        spans.push({ type: 'italic', text: match[3] });
      }
      lastIndex = match.index + match[0].length;
      match = regex.exec(text);
    }

    if (lastIndex < text.length) {
      spans.push({ type: 'normal', text: text.substring(lastIndex) });
    }

    if (spans.length === 0) {
      spans.push({ type: 'normal', text: text });
    }

    return spans;
  }
}
