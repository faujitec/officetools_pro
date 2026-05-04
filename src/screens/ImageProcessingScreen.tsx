import React, { useState, useRef } from 'react';
import { motion } from 'motion/react';
import { Header, BottomBanner, ProcessingOverlay } from '../components/CommonUI';
import { FileItem, Screen } from '../types';
import { Upload, Check, Image as ImageIcon, Download, Maximize, Scissors, Layers, FileDown, RefreshCw } from 'lucide-react';

interface ImageProcessingProps {
  onBack: () => void;
  toolId: string;
  onFileGenerated: (file: FileItem) => void;
}

export function ImageProcessingScreen({ onBack, toolId, onFileGenerated }: ImageProcessingProps) {
  const [image, setImage] = useState<string | null>(null);
  const [processing, setProcessing] = useState(false);
  const [progress, setProgress] = useState(0);
  const [isSuccess, setIsSuccess] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const tools: Record<string, { name: string; icon: any; action: string }> = {
    'resize': { name: 'Resize Image', icon: Maximize, action: 'Resizing...' },
    'crop': { name: 'Crop Image', icon: Scissors, action: 'Cropping...' },
    'remove-bg': { name: 'Remove Background', icon: Layers, action: 'Removing Background...' },
    'compress-img': { name: 'Compress Image', icon: FileDown, action: 'Compressing...' },
    'convert-img': { name: 'Convert Format', icon: RefreshCw, action: 'Converting...' },
  };

  const currentTool = tools[toolId] || tools['resize'];

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onload = () => setImage(reader.result as string);
      reader.readAsDataURL(file);
    }
  };

  const startProcessing = () => {
    setProcessing(true);
    setProgress(0);
    
    const interval = setInterval(() => {
      setProgress(prev => {
        if (prev >= 100) {
          clearInterval(interval);
          setTimeout(() => {
            setProcessing(false);
            setIsSuccess(true);
            onFileGenerated({
              id: Math.random().toString(36).substr(2, 9),
              name: `${currentTool.name.replace(' ', '_')}_${Date.now()}.png`,
              type: 'image',
              date: 'Just now'
            });
          }, 500);
          return 100;
        }
        return prev + 10;
      });
    }, 150);
  };

  return (
    <div className="iphone-vibe h-screen">
      {processing && <ProcessingOverlay progress={progress} message={currentTool.action} />}
      
      <Header title={currentTool.name} onBack={onBack} />
      
      <div className="flex-1 px-6 py-4 flex flex-col gap-6">
        {!image ? (
          <div 
            onClick={() => fileInputRef.current?.click()}
            className="flex-1 border-2 border-dashed border-gray-200 rounded-3xl flex flex-col items-center justify-center gap-4 bg-gray-50/50 cursor-pointer active:scale-98 transition-transform"
          >
            <div className="p-4 bg-primary/10 rounded-full">
              <Upload className="w-8 h-8 text-primary" />
            </div>
            <div className="text-center">
              <p className="font-bold">Choose Image</p>
              <p className="text-xs text-gray-500">PNG, JPG, HEIC up to 10MB</p>
            </div>
            <input 
              type="file" 
              ref={fileInputRef} 
              className="hidden" 
              accept="image/*" 
              onChange={handleFileSelect} 
            />
          </div>
        ) : (
          <div className="flex-1 flex flex-col gap-6">
            <div className="relative aspect-square w-full bg-gray-100 rounded-3xl overflow-hidden shadow-inner border border-gray-200">
               <img src={image} className="w-full h-full object-contain" alt="Preview" />
               {isSuccess && (
                 <div className="absolute inset-0 bg-primary/20 backdrop-blur-sm flex items-center justify-center">
                    <div className="bg-white p-4 rounded-full shadow-2xl">
                      <Check className="w-10 h-10 text-primary" />
                    </div>
                 </div>
               )}
            </div>

            <div className="space-y-4">
               {toolId === 'resize' && (
                <div className="grid grid-cols-2 gap-4">
                   <div className="space-y-1">
                      <label className="text-[10px] font-bold text-gray-400 uppercase">Width (px)</label>
                      <input type="number" defaultValue="1080" className="w-full p-3 bg-gray-50 rounded-xl border border-gray-100 outline-none focus:ring-2 focus:ring-primary/20" />
                   </div>
                   <div className="space-y-1">
                      <label className="text-[10px] font-bold text-gray-400 uppercase">Height (px)</label>
                      <input type="number" defaultValue="1080" className="w-full p-3 bg-gray-50 rounded-xl border border-gray-100 outline-none focus:ring-2 focus:ring-primary/20" />
                   </div>
                </div>
              )}

              {toolId === 'convert-img' && (
                <div className="flex gap-2 overflow-x-auto pb-2 scrollbar-hide">
                   {['JPEG', 'PNG', 'WEBP', 'PDF', 'HEIC'].map(fmt => (
                     <button key={fmt} className="px-6 py-2 bg-gray-100 rounded-full text-xs font-bold text-gray-600 border border-transparent hover:border-primary/30 transition-colors">
                       {fmt}
                     </button>
                   ))}
                </div>
              )}

              {isSuccess ? (
                <div className="space-y-3">
                  <button 
                    onClick={() => {
                      const link = document.createElement('a');
                      link.href = image || '#';
                      link.download = `Processed_${Date.now()}.png`;
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
                  onClick={startProcessing}
                  className="w-full bg-primary py-4 rounded-2xl text-white font-bold text-sm shadow-lg shadow-primary/20 active:scale-95 transition-all flex items-center justify-center gap-2"
                >
                  {currentTool.name}
                </button>
              )}
              
              {!isSuccess && (
                <button 
                  onClick={() => setImage(null)}
                  className="w-full py-2 text-sm font-semibold text-gray-400 hover:text-gray-600 dark:hover:text-gray-200"
                >
                  Change Image
                </button>
              )}
            </div>
          </div>
        )}
      </div>
      
      <BottomBanner />
    </div>
  );
}
