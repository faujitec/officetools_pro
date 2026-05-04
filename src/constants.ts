import { 
  FileSearch, 
  Image, 
  FileText, 
  RefreshCw, 
  Minimize2, 
  FolderOpen,
  Scissors,
  Layers,
  FileDown,
  Trash2,
  Lock,
  ScanLine,
  FileSpreadsheet
} from 'lucide-react';

import { Screen } from './types';

export const MAIN_TOOLS = [
  { id: 'scan', name: 'Scan PDF', icon: FileSearch, color: 'bg-blue-100 text-blue-600', screen: 'scanner' as Screen },
  { id: 'image', name: 'Image Tools', icon: Image, color: 'bg-orange-100 text-orange-600', screen: 'image-tools' as Screen },
  { id: 'pdf', name: 'PDF Tools', icon: FileText, color: 'bg-red-100 text-red-600', screen: 'pdf-tools' as Screen },
  { id: 'convert', name: 'Convert', icon: RefreshCw, color: 'bg-green-100 text-green-600', screen: 'convert' as Screen },
  { id: 'compress', name: 'Compress', icon: Minimize2, color: 'bg-yellow-100 text-yellow-600', screen: 'compress' as Screen },
  { id: 'files', name: 'My Files', icon: FolderOpen, color: 'bg-blue-100 text-blue-600', screen: 'my-files' as Screen },
];

export const IMAGE_TOOLS = [
  { id: 'resize', name: 'Resize Image', icon: Minimize2, screen: 'image-editor' as Screen },
  { id: 'crop', name: 'Crop Image', icon: Scissors, screen: 'image-editor' as Screen },
  { id: 'remove-bg', name: 'Remove Background', icon: Layers, screen: 'image-editor' as Screen },
  { id: 'compress-img', name: 'Compress Image', icon: FileDown, screen: 'image-editor' as Screen },
  { id: 'convert-img', name: 'Convert Format', icon: RefreshCw, screen: 'image-editor' as Screen },
];

export const PDF_TOOLS = [
  { id: 'merge', name: 'Merge PDFs', icon: Layers, screen: 'pdf-editor' as Screen },
  { id: 'split', name: 'Split PDF', icon: Scissors, screen: 'pdf-editor' as Screen },
  { id: 'rearrange', name: 'Rearrange Pages', icon: FileText, screen: 'pdf-editor' as Screen },
  { id: 'delete', name: 'Delete Pages', icon: Trash2, screen: 'pdf-editor' as Screen },
  { id: 'compress-pdf', name: 'Compress PDF', icon: Minimize2, screen: 'pdf-editor' as Screen },
  { id: 'password', name: 'Password Protect', icon: Lock, screen: 'pdf-editor' as Screen },
  { id: 'ocr', name: 'OCR (Extract Text)', icon: ScanLine, screen: 'pdf-editor' as Screen },
];

export const CONVERT_TOOLS = [
  { id: 'pdf-word', name: 'PDF to Word', icon: FileText, color: 'bg-blue-100 text-blue-600' },
  { id: 'word-pdf', name: 'Word to PDF', icon: FileText, color: 'bg-red-100 text-red-600' },
  { id: 'img-pdf', name: 'Image to PDF', icon: Image, color: 'bg-blue-100 text-blue-600' },
  { id: 'excel-pdf', name: 'Excel to PDF', icon: FileSpreadsheet, color: 'bg-green-100 text-green-600' },
];

