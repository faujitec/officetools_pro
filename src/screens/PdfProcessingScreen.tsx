import React, { useState, useRef } from 'react';
import { motion } from 'motion/react';
import { Header, BottomBanner, ProcessingOverlay } from '../components/CommonUI';
import { FileItem, Screen } from '../types';
import { 
  Upload, 
  Check, 
  FileText, 
  Download, 
  Layers, 
  Scissors, 
  Trash2, 
  Minimize2, 
  Lock, 
  ScanLine 
} from 'lucide-react';
import { extractTextFromImage } from '../services/geminiService';

interface PdfProcessingProps {
  onBack: () => void;
  toolId: string;
  onFileGenerated: (file: FileItem) => void;
  onOcrComplete: (text: string) => void;
}

export function PdfProcessingScreen({ onBack, toolId, onFileGenerated, onOcrComplete }: PdfProcessingProps) {
  const [files, setFiles] = useState<File[]>([]);
  const [processing, setProcessing] = useState(false);
  const [progress, setProgress] = useState(0);
  const [isSuccess, setIsSuccess] = useState(false);
  const [password, setPassword] = useState('');
  const fileInputRef = useRef<HTMLInputElement>(null);

  const tools: Record<string, { name: string; icon: any; action: string }> = {
    'merge': { name: 'Merge PDFs', icon: Layers, action: 'Merging PDFs...' },
    'split': { name: 'Split PDF', icon: Scissors, action: 'Splitting PDF...' },
    'rearrange': { name: 'Rearrange Pages', icon: FileText, action: 'Rearranging...' },
    'delete': { name: 'Delete Pages', icon: Trash2, action: 'Deleting Pages...' },
    'compress-pdf': { name: 'Compress PDF', icon: Minimize2, action: 'Compressing PDF...' },
    'password': { name: 'Password Protect', icon: Lock, action: 'Encrypting PDF...' },
    'ocr': { name: 'OCR (Extract Text)', icon: ScanLine, action: 'Analyzing Text...' },
  };

  const currentTool = tools[toolId] || tools['merge'];

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const selectedFiles = Array.from(e.target.files || []);
    if (selectedFiles.length > 0) {
      setFiles(prev => toolId === 'merge' ? [...prev, ...selectedFiles] : [selectedFiles[0]]);
    }
  };

  const startProcessing = async () => {
    setProcessing(true);
    setProgress(0);
    
    const interval = setInterval(() => {
      setProgress(prev => {
        if (prev >= 100) {
          clearInterval(interval);
          return 100;
        }
        return prev + (toolId === 'ocr' ? 2 : 10);
      });
    }, 100);

    try {
      if (toolId === 'ocr' && files.length > 0) {
        const file = files[0];
        const reader = new FileReader();
        reader.onload = async () => {
          try {
            const base64 = (reader.result as string).split(',')[1];
            const text = await extractTextFromImage(base64, file.type);
            clearInterval(interval);
            setProgress(100);
            setTimeout(() => {
              setProcessing(false);
              onOcrComplete(text);
            }, 500);
          } catch (err) {
            alert("OCR Failed");
            setProcessing(false);
          }
        };
        reader.readAsDataURL(file);
      } else {
        // Mock PDF processing for others
        setTimeout(() => {
          clearInterval(interval);
          setProgress(100);
          setTimeout(() => {
            setProcessing(false);
            setIsSuccess(true);
            onFileGenerated({
              id: Math.random().toString(36).substr(2, 9),
              name: `${toolId}_${Date.now()}.pdf`,
              type: 'pdf',
              date: 'Just now'
            });
          }, 500);
        }, 2000);
      }
    } catch (err) {
      setProcessing(false);
      alert("Processing failed");
    }
  };

  return (
    <div className="iphone-vibe h-screen">
      {processing && <ProcessingOverlay progress={progress} message={currentTool.action} />}
      
      <Header title={currentTool.name} onBack={onBack} />
      
      <div className="flex-1 px-6 py-4 flex flex-col gap-6 overflow-y-auto">
        <div 
          onClick={() => fileInputRef.current?.click()}
          className="shrink-0 h-48 border-2 border-dashed border-gray-200 rounded-3xl flex flex-col items-center justify-center gap-4 bg-gray-50/50 cursor-pointer active:scale-98 transition-transform"
        >
          <div className="p-4 bg-primary/10 rounded-full">
            <Upload className="w-8 h-8 text-primary" />
          </div>
          <div className="text-center">
            <p className="font-bold">
              {toolId === 'merge' ? 'Add PDF Files' : 'Select PDF File'}
            </p>
            <p className="text-xs text-gray-500">PDF up to 50MB</p>
          </div>
          <input 
            type="file" 
            ref={fileInputRef} 
            className="hidden" 
            accept="application/pdf,image/*" 
            multiple={toolId === 'merge'}
            onChange={handleFileSelect} 
          />
        </div>

        {files.length > 0 && (
          <div className="space-y-3">
            <p className="text-[10px] font-bold text-gray-400 uppercase tracking-wider">Selected Files</p>
            {files.map((f, i) => (
              <div key={i} className="p-4 bg-white rounded-2xl border border-gray-100 flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <FileText className="w-5 h-5 text-red-500" />
                  <span className="text-sm font-medium truncate max-w-[200px]">{f.name}</span>
                </div>
                <button onClick={() => setFiles(prev => prev.filter((_, idx) => idx !== i))}>
                   <Trash2 className="w-4 h-4 text-gray-400 hover:text-red-500" />
                </button>
              </div>
            ))}
          </div>
        )}

        <div className="mt-auto space-y-4">
          {toolId === 'password' && (
            <div className="space-y-1">
              <label className="text-[10px] font-bold text-gray-400 uppercase">Set Password</label>
              <input 
                type="password" 
                placeholder="Enter password..."
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full p-4 bg-gray-50 rounded-2xl border border-gray-100 outline-none focus:ring-2 focus:ring-primary/20" 
              />
            </div>
          )}

          {toolId === 'compress-pdf' && (
             <div className="p-4 bg-blue-50 rounded-2xl border border-blue-100 flex items-center justify-between">
                <span className="text-sm font-semibold text-blue-700">Compression Level</span>
                <span className="text-sm font-bold text-blue-700">High</span>
             </div>
          )}

          {isSuccess ? (
            <div className="space-y-3">
              <button 
                onClick={() => {
                  const link = document.createElement('a');
                  link.href = '#'; // In a real app, this would be the actual PDF
                  link.download = `Processed_${Date.now()}.pdf`;
                  document.body.appendChild(link);
                  link.click();
                  document.body.removeChild(link);
                }}
                className="w-full bg-primary py-4 rounded-2xl text-white font-bold text-sm shadow-lg shadow-primary/20 active:scale-95 transition-all flex items-center justify-center gap-2"
              >
                <Download className="w-5 h-5 text-white" />
                Download Now
              </button>
              <button 
                onClick={onBack}
                className="w-full py-4 rounded-2xl text-primary font-bold text-sm border border-primary/20 active:scale-95 transition-all flex items-center justify-center gap-2"
              >
                Finish & Close
              </button>
            </div>
          ) : (
            <button 
              disabled={files.length === 0}
              onClick={startProcessing}
              className="w-full bg-primary disabled:bg-gray-300 py-4 rounded-2xl text-white font-bold text-sm shadow-lg shadow-primary/20 active:scale-95 transition-all flex items-center justify-center gap-2"
            >
              Process {currentTool.name}
            </button>
          )}
        </div>
      </div>
      
      <BottomBanner />
    </div>
  );
}
