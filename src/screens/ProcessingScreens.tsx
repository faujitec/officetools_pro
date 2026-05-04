import React, { useState } from 'react';
import { motion } from 'motion/react';
import { ChevronRight, Check, Download } from 'lucide-react';
import { Header, BottomBanner, ProcessingOverlay } from '../components/CommonUI';
import { CONVERT_TOOLS } from '../constants';
import { FileItem } from '../types';

interface ProcessingProps {
  onBack: () => void;
  onFileGenerated: (file: FileItem) => void;
}

export function Convert({ onBack, onFileGenerated }: ProcessingProps) {
  const [processing, setProcessing] = useState(false);
  const [progress, setProgress] = useState(0);
  const [isSuccess, setIsSuccess] = useState(false);
  const [lastTool, setLastTool] = useState('');

  const startProcessing = (toolName: string) => {
    setProcessing(true);
    setIsSuccess(false);
    setLastTool(toolName);
    setProgress(0);
    const interval = setInterval(() => {
      setProgress(prev => {
        if (prev >= 100) {
          clearInterval(interval);
          setTimeout(() => {
            onFileGenerated({
              id: Math.random().toString(36).substr(2, 9),
              name: `Converted_${toolName.replace(/ /g, '_')}_${Date.now()}.pdf`,
              type: 'pdf',
              date: 'Just now'
            });
            setProcessing(false);
            setIsSuccess(true);
          }, 500);
          return 100;
        }
        return prev + 5;
      });
    }, 50);
  };

  return (
    <div className="iphone-vibe h-screen">
      {processing && <ProcessingOverlay progress={progress} message="Converting File..." />}
      
      <Header title="Convert Files" onBack={onBack} />
      
      <div className="flex-1 px-6 py-4 flex flex-col gap-4 overflow-y-auto">
        {isSuccess ? (
          <motion.div 
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            className="flex-1 flex flex-col items-center justify-center gap-8 bg-white rounded-[40px] p-8 border border-gray-100 shadow-sm"
          >
            <div className="w-24 h-24 bg-green-50 rounded-full flex items-center justify-center">
              <Check className="w-12 h-12 text-green-500" />
            </div>
            <div className="text-center space-y-2">
              <h3 className="text-xl font-bold">Conversion Successful!</h3>
              <p className="text-sm text-gray-500">Your {lastTool} conversion is complete and ready to download.</p>
            </div>
            
            <div className="w-full space-y-3">
              <button 
                onClick={() => {
                  const link = document.createElement('a');
                  link.href = '#';
                  link.download = `Converted_${lastTool.replace(/ /g, '_')}.pdf`;
                  document.body.appendChild(link);
                  link.click();
                  document.body.removeChild(link);
                }}
                className="w-full bg-primary py-4 rounded-2xl text-white font-bold text-sm shadow-lg shadow-primary/20 active:scale-95 transition-all flex items-center justify-center gap-2"
              >
                <Download className="w-5 h-5" />
                Download Now
              </button>
              <button 
                onClick={onBack}
                className="w-full py-4 rounded-2xl text-primary font-bold text-sm border border-primary/20 active:scale-95 transition-all"
              >
                Finish
              </button>
            </div>
          </motion.div>
        ) : (
          <>
            <div className="grid grid-cols-2 gap-4">
              {CONVERT_TOOLS.map(tool => (
                <motion.div
                  key={tool.id}
                  whileTap={{ scale: 0.95 }}
                  onClick={() => startProcessing(tool.name)}
                  className="p-6 bg-white rounded-3xl border border-gray-100 shadow-sm flex flex-col items-center gap-4 transition-colors cursor-pointer"
                >
                  <div className={`p-4 rounded-2xl ${tool.color}`}>
                    <tool.icon className="w-8 h-8" />
                  </div>
                  <span className="text-sm font-bold text-center">{tool.name}</span>
                </motion.div>
              ))}
            </div>
            
            <button className="w-full py-4 px-6 bg-gray-50 border border-gray-100 rounded-2xl text-sm font-semibold text-gray-600 flex items-center justify-between transition-colors mt-auto">
              <span>Other Conversions</span>
              <ChevronRight className="w-4 h-4" />
            </button>
          </>
        )}
      </div>
      
      <BottomBanner />
    </div>
  );
}

export function Compress({ onBack, onFileGenerated }: ProcessingProps) {
  const [level, setLevel] = useState(50);
  const [activeTab, setActiveTab] = useState('image');
  const [processing, setProcessing] = useState(false);
  const [progress, setProgress] = useState(0);
  const [isSuccess, setIsSuccess] = useState(false);
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const fileInputRef = React.useRef<HTMLInputElement>(null);

  const tabs = [
    { id: 'image', name: 'Compress Image', type: 'image' as const, ext: 'jpg', mime: 'image/*' },
    { id: 'pdf', name: 'Compress PDF', type: 'pdf' as const, ext: 'pdf', mime: 'application/pdf' },
    { id: 'doc', name: 'Compress Document', type: 'docx' as const, ext: 'docx', mime: '.doc,.docx' },
  ];

  const currentTab = tabs.find(t => t.id === activeTab)!;

  const handleCompress = () => {
    if (!selectedFile) {
      alert("Please select a file first");
      return;
    }

    setProcessing(true);
    setProgress(0);
    
    const interval = setInterval(() => {
      setProgress(prev => {
        if (prev >= 100) {
          clearInterval(interval);
          setTimeout(() => {
            onFileGenerated({
              id: Math.random().toString(36).substr(2, 9),
              name: `Compressed_${level}pct_${selectedFile.name}`,
              type: currentTab.type,
              date: 'Just now'
            });
            setProcessing(false);
            setIsSuccess(true);
          }, 500);
          return 100;
        }
        return prev + 10;
      });
    }, 100);
  };

  const handleFinish = () => {
    setIsSuccess(false);
    setSelectedFile(null);
    onBack();
  };

  return (
    <div className="iphone-vibe h-screen">
      {processing && <ProcessingOverlay progress={progress} message={`Compressing ${currentTab.name}...`} />}
      
      <Header title="Compress Files" onBack={onBack} />
      
      <div className="flex-1 px-6 py-4 flex flex-col gap-6 overflow-y-auto">
        <div className="flex bg-gray-100 p-1 rounded-2xl">
          {tabs.map(tab => (
            <button
              key={tab.id}
              onClick={() => {
                setActiveTab(tab.id);
                setSelectedFile(null);
                setIsSuccess(false);
              }}
              className={`flex-1 py-3 px-2 rounded-xl text-[10px] font-bold uppercase tracking-wider transition-all ${
                activeTab === tab.id 
                ? 'bg-white text-primary shadow-sm' 
                : 'text-gray-400'
              }`}
            >
              {tab.id}
            </button>
          ))}
        </div>

        <div 
          onClick={() => !isSuccess && fileInputRef.current?.click()}
          className={`shrink-0 h-40 border-2 border-dashed ${isSuccess ? 'border-primary bg-primary/5' : 'border-gray-200 bg-gray-50/50'} rounded-3xl flex flex-col items-center justify-center gap-3 cursor-pointer active:scale-98 transition-all`}
        >
          {isSuccess ? (
            <div className="flex flex-col items-center gap-2">
              <div className="p-3 bg-primary rounded-full">
                <Check className="w-6 h-6 text-white" />
              </div>
              <p className="text-sm font-bold text-primary">Compression Complete!</p>
            </div>
          ) : (
            <>
              <div className="p-3 bg-primary/10 rounded-full">
                <ChevronRight className="w-6 h-6 text-primary rotate-90" />
              </div>
              <div className="text-center">
                <p className="text-sm font-bold">
                  {selectedFile ? selectedFile.name : `Select ${currentTab.name}`}
                </p>
                <p className="text-[10px] text-gray-500 font-medium">Tap to upload file</p>
              </div>
            </>
          )}
          <input 
            type="file" 
            ref={fileInputRef} 
            className="hidden" 
            accept={currentTab.mime} 
            onChange={(e) => setSelectedFile(e.target.files?.[0] || null)} 
          />
        </div>

        <div className="bg-white p-8 rounded-3xl border border-gray-100 shadow-sm space-y-8 mt-auto">
           {!isSuccess && (
             <div className="space-y-4">
                <div className="flex justify-between items-center">
                  <p className="text-xs font-bold text-gray-700 uppercase tracking-widest">Compression Level</p>
                  <span className="text-primary font-bold text-sm">{level}%</span>
                </div>
                
                <div className="flex flex-col gap-4">
                   <input 
                     type="range" 
                     min="10" 
                     max="90" 
                     value={level} 
                     onChange={(e) => setLevel(parseInt(e.target.value))}
                     className="w-full accent-primary h-1.5 bg-gray-100 rounded-lg appearance-none cursor-pointer"
                   />
                   <div className="flex justify-between text-[10px] font-bold text-gray-400 uppercase tracking-wider">
                     <span>Small Size</span>
                     <span>Best Quality</span>
                   </div>
                </div>
             </div>
           )}

           {isSuccess ? (
             <div className="space-y-4">
                <button 
                  onClick={() => {
                    const link = document.createElement('a');
                    link.href = '#';
                    link.download = `Compressed_${selectedFile?.name || 'file'}`;
                    document.body.appendChild(link);
                    link.click();
                    document.body.removeChild(link);
                  }}
                  className="w-full bg-primary py-4 rounded-2xl text-white font-bold text-sm shadow-lg shadow-primary/20 active:scale-95 transition-all flex items-center justify-center gap-2"
                >
                  <Download className="w-5 h-5" />
                  Download Now
                </button>
                <button 
                  onClick={handleFinish}
                  className="w-full py-4 rounded-2xl text-primary font-bold text-sm border border-primary/20 active:scale-95 transition-all"
                >
                  Finish & Close
                </button>
             </div>
           ) : (
             <button 
               onClick={handleCompress}
               disabled={!selectedFile}
               className="w-full bg-primary disabled:opacity-30 py-4 rounded-2xl text-white font-bold text-sm shadow-lg shadow-primary/20 active:scale-95 transition-all"
             >
              Compress Now
            </button>
           )}
        </div>
      </div>
      
      <BottomBanner />
    </div>
  );
}
