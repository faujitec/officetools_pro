import React, { useState, useRef, useEffect } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { Camera, RefreshCcw, Save, Focus, User, X, ChevronRight, MoreVertical, Loader2, ShieldCheck, Download, Trash2, Edit3, Share2 as ShareIcon } from 'lucide-react';
import { Header, BottomBanner, ProcessingOverlay } from '../components/CommonUI';
import { FileItem, Screen } from '../types';
import { extractTextFromImage } from '../services/geminiService';

export function Scanner({ onBack, onOcrComplete, onFileGenerated }: { onBack: () => void, onOcrComplete: (text: string) => void, onFileGenerated: (file: FileItem) => void }) {
  const [mode, setMode] = useState<'auto' | 'manual'>('auto');
  const [processing, setProcessing] = useState(false);
  const [stream, setStream] = useState<MediaStream | null>(null);
  const [capturedImage, setCapturedImage] = useState<string | null>(null);
  const [flash, setFlash] = useState(false);
  
  const videoRef = useRef<HTMLVideoElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);

  // Start camera
  useEffect(() => {
    async function startCamera() {
      try {
        const mediaStream = await navigator.mediaDevices.getUserMedia({ 
          video: { facingMode: 'environment' }, 
          audio: false 
        });
        setStream(mediaStream);
        if (videoRef.current) {
          videoRef.current.srcObject = mediaStream;
        }
      } catch (err) {
        console.error("Camera access denied:", err);
      }
    }
    startCamera();
    return () => {
      stream?.getTracks().forEach(track => track.stop());
    };
  }, []);

  const handleCapture = () => {
    if (!videoRef.current || !canvasRef.current) return;
    
    setFlash(true);
    setTimeout(() => setFlash(false), 150);

    const context = canvasRef.current.getContext('2d');
    if (context) {
      canvasRef.current.width = videoRef.current.videoWidth;
      canvasRef.current.height = videoRef.current.videoHeight;
      context.drawImage(videoRef.current, 0, 0);
      const dataUrl = canvasRef.current.toDataURL('image/jpeg');
      setCapturedImage(dataUrl);
    }
  };

  const handleSave = async () => {
    if (!capturedImage) return;
    setProcessing(true);
    
    // Simulate processing delay
    setTimeout(() => {
      onFileGenerated({
        id: Math.random().toString(36).substr(2, 9),
        name: `Scan_${Date.now()}.pdf`,
        type: 'pdf',
        date: 'Just now'
      });
      setProcessing(false);
    }, 1500);
  };

  const handleRetake = () => {
    setCapturedImage(null);
  };

  return (
    <div className="iphone-vibe h-screen bg-black overflow-hidden">
      {processing && <ProcessingOverlay progress={85} message="Converting to PDF..." />}
      
      {/* Camera Preview or Captured Image */}
      <div className="absolute inset-0 flex items-center justify-center">
        {capturedImage ? (
          <img src={capturedImage} className="w-full h-full object-cover" alt="Captured" />
        ) : (
          <video 
            ref={videoRef} 
            autoPlay 
            playsInline 
            className="w-full h-full object-cover"
          />
        )}
        
        {/* Scanning Frame Overlay (only visible when not captured) */}
        {!capturedImage && (
          <div className="absolute inset-0 flex items-center justify-center p-12 pointer-events-none">
            <div className="w-full aspect-[3/4] border-2 border-primary/50 relative">
               <motion.div 
                 animate={{ opacity: [0.3, 0.6, 0.3] }}
                 transition={{ repeat: Infinity, duration: 2 }}
                 className="absolute inset-0 bg-primary/5"
               />
               {/* Corners */}
               <div className="absolute -top-1 -left-1 w-6 h-6 border-t-4 border-l-4 border-primary rounded-tl-lg" />
               <div className="absolute -top-1 -right-1 w-6 h-6 border-t-4 border-r-4 border-primary rounded-tr-lg" />
               <div className="absolute -bottom-1 -left-1 w-6 h-6 border-b-4 border-l-4 border-primary rounded-bl-lg" />
               <div className="absolute -bottom-1 -right-1 w-6 h-6 border-b-4 border-r-4 border-primary rounded-br-lg" />
            </div>
          </div>
        )}
      </div>

      {/* Hidden Canvas for Capture */}
      <canvas ref={canvasRef} className="hidden" />
      
      {/* Flash Effect */}
      <AnimatePresence>
        {flash && (
          <motion.div 
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="absolute inset-0 bg-white z-50 pointer-events-none"
          />
        )}
      </AnimatePresence>

      <div className="absolute top-12 left-0 right-0 px-6 flex justify-between items-center text-white z-20">
        <button onClick={onBack} className="p-2 bg-black/40 rounded-full backdrop-blur-md">
          <X className="w-6 h-6" />
        </button>
        <div className="px-4 py-1.5 bg-black/40 rounded-full backdrop-blur-md text-[10px] font-bold uppercase tracking-wider">
          {capturedImage ? 'Preview' : 'Document Scanner'}
        </div>
      </div>

      <div className="absolute bottom-8 left-0 right-0 px-8 flex flex-col items-center gap-8 z-20">
        {!capturedImage && (
          <div className="flex bg-black/40 backdrop-blur-md rounded-full p-1 gap-1 border border-white/10">
            <button 
              onClick={() => setMode('auto')}
              className={`px-6 py-2 rounded-full text-xs font-bold transition-colors ${mode === 'auto' ? 'bg-white text-black' : 'text-white'}`}
            >
              AUTO
            </button>
            <button 
              onClick={() => setMode('manual')}
              className={`px-6 py-2 rounded-full text-xs font-bold transition-colors ${mode === 'manual' ? 'bg-white text-black' : 'text-white'}`}
            >
              MANUAL
            </button>
          </div>
        )}

        <div className="flex items-center justify-between w-full h-24">
          <button 
            onClick={capturedImage ? handleRetake : undefined}
            className={`flex flex-col items-center gap-1 transition-opacity ${capturedImage ? 'opacity-100' : 'opacity-30'}`}
          >
            <RefreshCcw className="w-6 h-6 text-white" />
            <span className="text-[10px] text-white font-medium uppercase">Retake</span>
          </button>
          
          <button 
            onClick={capturedImage ? handleSave : handleCapture}
            className="w-18 h-18 rounded-full bg-primary border-4 border-white/30 flex items-center justify-center active:scale-90 transition-transform"
          >
            {capturedImage ? (
              <Save className="w-8 h-8 text-white" />
            ) : (
              <div className="w-14 h-14 rounded-full bg-white flex items-center justify-center" />
            )}
          </button>

          <div className="flex flex-col items-center gap-1 opacity-80">
            <User className="w-6 h-6 text-white" />
            <span className="text-[10px] text-white font-medium uppercase">Filter</span>
          </div>
        </div>
      </div>
    </div>
  );
}

export function MyFiles({ onBack, files, onDelete }: { onBack: () => void, files: FileItem[], onDelete?: (id: string) => void }) {
  const [activeMenuId, setActiveMenuId] = useState<string | null>(null);

  return (
    <div className="iphone-vibe h-screen relative">
      <Header title="My Files" onBack={onBack} onMenu={() => {}} />
      
      <div className="flex-1 overflow-y-auto" onClick={() => setActiveMenuId(null)}>
        <div className="px-6 py-2 space-y-4">
           {['Recent', 'Favorites', 'Folders'].map(item => (
             <div key={item} className="flex items-center justify-between py-2 border-b border-gray-100">
                <span className="font-semibold text-gray-700">{item}</span>
                <ChevronRight className="w-5 h-5 text-gray-400" />
             </div>
           ))}
        </div>

        <div className="mt-6 px-6 space-y-3 pb-20">
          {files.length === 0 ? (
            <div className="text-center py-12 space-y-2">
               <p className="text-gray-400 text-sm italic">No files yet.</p>
            </div>
          ) : (
            files.map(file => (
              <div key={file.id} className="p-4 bg-white rounded-2xl flex items-center justify-between border border-gray-50 shadow-sm relative">
                <div className="flex items-center gap-4">
                  <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center">
                      <FileSearch className="w-6 h-6 text-primary" />
                  </div>
                  <div className="truncate max-w-[200px]">
                      <p className="text-sm font-semibold text-gray-800 truncate">{file.name}</p>
                      <p className="text-[10px] text-gray-400 font-medium">{file.date}</p>
                  </div>
                </div>
                
                <div className="relative">
                  <button 
                    onClick={(e) => {
                      e.stopPropagation();
                      setActiveMenuId(activeMenuId === file.id ? null : file.id);
                    }}
                    className="p-2 -mr-2 bg-gray-50 rounded-full active:bg-gray-100 transition-colors"
                  >
                    <MoreVertical className="w-4 h-4 text-gray-400" />
                  </button>

                  <AnimatePresence>
                    {activeMenuId === file.id && (
                      <motion.div 
                        initial={{ opacity: 0, scale: 0.95, y: -10 }}
                        animate={{ opacity: 1, scale: 1, y: 0 }}
                        exit={{ opacity: 0, scale: 0.95, y: -10 }}
                        className="absolute right-0 top-10 w-36 bg-white rounded-2xl shadow-2xl border border-gray-100 z-[100] overflow-hidden"
                      >
                         <button 
                           onClick={(e) => {
                             e.stopPropagation();
                             const link = document.createElement('a');
                             link.href = file.content || '#';
                             link.download = file.name;
                             document.body.appendChild(link);
                             link.click();
                             document.body.removeChild(link);
                             setActiveMenuId(null);
                           }}
                           className="w-full px-4 py-3 text-left text-xs font-semibold hover:bg-gray-50 border-b border-gray-100 transition-colors flex items-center gap-2"
                         >
                           <Download className="w-3.5 h-3.5" />
                           Download
                         </button>
                         <button 
                           onClick={(e) => {
                             e.stopPropagation();
                             if (navigator.share) {
                               navigator.share({
                                 title: file.name,
                                 text: `Check out this file: ${file.name}`,
                                 url: window.location.href, // In a real app, this would be a file link
                               }).catch(() => {});
                             } else {
                               alert(`Sharing ${file.name}`);
                             }
                             setActiveMenuId(null);
                           }}
                           className="w-full px-4 py-3 text-left text-xs font-semibold hover:bg-gray-50 border-b border-gray-100 transition-colors flex items-center gap-2"
                         >
                           <ShareIcon className="w-3.5 h-3.5" />
                           Share File
                         </button>
                         <button className="w-full px-4 py-3 text-left text-xs font-semibold hover:bg-gray-50 border-b border-gray-100 transition-colors flex items-center gap-2">
                           <Edit3 className="w-3.5 h-3.5" />
                           Rename
                         </button>
                         <button 
                          onClick={() => onDelete?.(file.id)}
                          className="w-full px-4 py-3 text-left text-xs font-bold text-red-500 hover:bg-red-50 transition-colors flex items-center gap-2"
                         >
                           <Trash2 className="w-3.5 h-3.5" />
                           Delete
                         </button>
                      </motion.div>
                    )}
                  </AnimatePresence>
                </div>
              </div>
            ))
          )}
        </div>
      </div>
      <BottomBanner />
    </div>
  );
}

const FileSearch = ({ className }: { className: string }) => (
  <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor">
    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
  </svg>
);

export function SettingsScreen({ onBack }: { onBack: () => void }) {
  const [vibration, setVibration] = useState(true);
  const [notifications, setNotifications] = useState(true);
  const [cloudSync, setCloudSync] = useState(false);

  const toggleItem = (label: string, value: boolean, setter: (v: boolean) => void) => (
    <div className="flex items-center justify-between p-4 bg-white rounded-2xl border border-gray-100">
      <span className="text-sm font-bold text-gray-700">{label}</span>
      <button 
        onClick={() => setter(!value)}
        className={`w-12 h-6 rounded-full transition-colors relative ${value ? 'bg-primary' : 'bg-gray-200'}`}
      >
        <motion.div 
          animate={{ x: value ? 26 : 2 }}
          className="absolute top-1 w-4 h-4 bg-white rounded-full shadow-sm"
        />
      </button>
    </div>
  );

  return (
    <div className="iphone-vibe h-screen">
      <Header title="Settings" onBack={onBack} />
      <div className="px-6 py-4 space-y-6">
        <div className="space-y-3">
          <h3 className="text-[10px] font-bold text-gray-400 uppercase tracking-widest ml-1">General Preferences</h3>
          <div className="space-y-2">
            {toggleItem("Haptic Feedback", vibration, setVibration)}
            {toggleItem("Push Notifications", notifications, setNotifications)}
          </div>
        </div>

        <div className="space-y-3">
          <h3 className="text-[10px] font-bold text-gray-400 uppercase tracking-widest ml-1">Storage & Cloud</h3>
          {toggleItem("Auto-sync to Cloud", cloudSync, setCloudSync)}
          <button className="w-full p-4 bg-white rounded-2xl border border-gray-100 flex items-center justify-between group">
             <span className="text-sm font-bold text-gray-700">Clear App Cache</span>
             <ChevronRight className="w-4 h-4 text-gray-300 group-hover:text-primary transition-colors" />
          </button>
        </div>

        <div className="space-y-3">
          <h3 className="text-[10px] font-bold text-gray-400 uppercase tracking-widest ml-1">Account & Support</h3>
          <button className="w-full p-4 bg-red-50 rounded-2xl border border-red-100 flex items-center justify-center">
             <span className="text-sm font-black text-red-600">Delete My Local Data</span>
          </button>
        </div>
      </div>
      <BottomBanner />
    </div>
  );
}

export function AboutScreen({ onBack }: { onBack: () => void }) {
  return (
    <div className="iphone-vibe h-screen overflow-y-auto pb-20">
      <Header title="About ToolsPro" onBack={onBack} />
      <div className="px-8 py-6 space-y-8">
        <div className="flex flex-col items-center gap-4 text-center">
          <div className="w-20 h-20 bg-primary rounded-3xl flex items-center justify-center text-white font-bold text-2xl shadow-xl shadow-primary/20">
            TP
          </div>
          <div>
            <h2 className="text-2xl font-black">Office ToolsPro</h2>
            <p className="text-sm font-bold text-primary tracking-widest uppercase">Version 4.8.2-PRO</p>
          </div>
        </div>

        <div className="space-y-4">
          <h3 className="text-xs font-bold text-gray-400 uppercase tracking-widest">Our Mission</h3>
          <p className="text-gray-600 leading-relaxed text-sm">
            ToolsPro is dedicated to providing the most intuitive and powerful mobile utility tools for professionals and students alike. Our goal is to simplify document management and image processing directly from your smartphone.
          </p>
        </div>

        <div className="space-y-4">
          <h3 className="text-xs font-bold text-gray-400 uppercase tracking-widest">What's New</h3>
          <div className="space-y-3">
             {[
               "AI-Powered Advanced OCR",
               "Batch PDF Merging Implementation",
               "High-Fidelity Image Compression",
               "Redesigned iOS-inspired Interface"
             ].map((feature, i) => (
               <div key={i} className="flex gap-3 items-start">
                 <div className="w-1.5 h-1.5 rounded-full bg-primary mt-1.5" />
                 <p className="text-sm font-medium text-gray-700">{feature}</p>
               </div>
             ))}
          </div>
        </div>

        <div className="p-6 bg-gray-50 rounded-3xl border border-gray-100 text-center">
           <p className="text-xs text-gray-400 font-medium italic">
             "The only tool you'll ever need for your daily office tasks."
           </p>
        </div>
      </div>
      <BottomBanner />
    </div>
  );
}

export function PrivacyScreen({ onBack }: { onBack: () => void }) {
  const sections = [
    { title: "Data Collection", text: "We do not store your documents or images on our servers. All processing is done locally on your device or via secure, encrypted channels that purge data immediately after processing." },
    { title: "User Privacy", text: "Your privacy is our priority. We do not track your personal information or usage patterns in a way that can be linked back to you." },
    { title: "Third-Party Services", text: "We use Google Gemini for advanced OCR. Your data is sent directly to Google's secure APIs and is not used for model training." }
  ];

  return (
    <div className="iphone-vibe h-screen overflow-y-auto pb-20">
      <Header title="Privacy Policy" onBack={onBack} />
      <div className="px-8 py-6 space-y-8">
        <div className="p-4 bg-green-50 rounded-2xl border border-green-100 flex items-center gap-3">
          <ShieldCheck className="w-6 h-6 text-green-600" />
          <span className="text-sm font-bold text-green-700">Your data is safe & private</span>
        </div>

        {sections.map((section, i) => (
          <div key={i} className="space-y-3">
            <h3 className="text-xs font-bold text-gray-400 uppercase tracking-widest">{section.title}</h3>
            <p className="text-gray-600 leading-relaxed text-sm">{section.text}</p>
          </div>
        ))}

        <div className="pt-4 border-t border-gray-100 text-[10px] text-gray-400 font-medium text-center">
          Last updated: April 24, 2026
        </div>
      </div>
      <BottomBanner />
    </div>
  );
}

export function OCRResult({ onBack, text }: { onBack: () => void, text: string }) {
  const [copied, setCopied] = useState(false);

  const handleCopy = () => {
    navigator.clipboard.writeText(text);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className="iphone-vibe h-screen">
      <Header title="OCR Result" onBack={onBack} />
      
      <div className="flex-1 px-6 py-4">
        <div className="bg-white rounded-3xl p-6 shadow-sm border border-gray-100 min-h-[300px] overflow-y-auto">
          <pre className="whitespace-pre-wrap font-sans text-sm text-gray-700 leading-relaxed outline-none" contentEditable>
            {text}
          </pre>
        </div>
        
        <button 
          onClick={handleCopy}
          className="w-full mt-8 bg-primary py-4 rounded-2xl text-white font-bold text-sm shadow-lg shadow-primary/20 active:scale-95 transition-transform flex items-center justify-center gap-2"
        >
          {copied ? '✓ Copied!' : 'Copy Text'}
        </button>
      </div>
      
      <BottomBanner />
    </div>
  );
}
