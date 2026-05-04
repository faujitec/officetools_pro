export type Screen = 
  | 'home' 
  | 'image-tools' 
  | 'pdf-tools' 
  | 'scanner' 
  | 'convert' 
  | 'compress' 
  | 'my-files' 
  | 'ocr-result'
  | 'image-editor'
  | 'pdf-editor'
  | 'about'
  | 'privacy'
  | 'settings';

export interface Tool {
  id: string;
  name: string;
  icon: any;
  screen?: Screen;
  color: string;
}

export interface FileItem {
  id: string;
  name: string;
  type: 'pdf' | 'image' | 'docx' | 'txt';
  date: string;
  content?: string; // For OCR result or base64 preview
}

export type ProcessingState = 'idle' | 'processing' | 'success' | 'error';
