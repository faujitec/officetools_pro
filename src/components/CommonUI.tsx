import React, { useState } from 'react';
import { ArrowLeft, Menu, Moon, Sun, Search, X, Settings, User, Star, Share2, Info, ShieldCheck } from 'lucide-react';
import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';
import { motion, AnimatePresence } from 'motion/react';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

interface HeaderProps {
  title: string;
  onBack?: () => void;
  onMenu?: () => void;
  showSearch?: boolean;
}

export function Header({ title, onBack, onMenu, showSearch }: HeaderProps) {
  return (
    <div className="px-6 pt-12 pb-4 space-y-4 shrink-0 bg-white z-10">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          {onBack ? (
            <button onClick={onBack} className="p-1 -ml-1 active:opacity-50 transition-opacity">
              <ArrowLeft className="w-6 h-6" />
            </button>
          ) : (
            <button onClick={onMenu} className="p-1 -ml-1 active:opacity-50 transition-opacity">
              <Menu className="w-6 h-6" />
            </button>
          )}
          <h1 className="text-xl font-bold text-primary">{title}</h1>
        </div>
      </div>
      
      {showSearch && (
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input 
            type="text" 
            placeholder="Search tools..." 
            className="w-full pl-10 pr-4 py-3 bg-gray-100 dark:bg-white/5 rounded-2xl text-sm focus:outline-none focus:ring-2 focus:ring-primary/20 dark:text-white transition-all outline-none"
          />
        </div>
      )}
    </div>
  );
}

interface SidebarProps {
  isOpen: boolean;
  onClose: () => void;
  onNavigate: (screen: any) => void;
}

export function Sidebar({ isOpen, onClose, onNavigate }: SidebarProps) {
  const handleAction = (label: string) => {
    onClose();
    switch (label) {
      case 'Rate Us':
        alert("Thanks for your interest! Rating feature is coming soon to the App Store.");
        break;
      case 'Share App':
        if (navigator.share) {
          navigator.share({
            title: 'Office ToolsPro',
            text: 'Check out this awesome office utility app!',
            url: window.location.href,
          }).catch(() => {});
        } else {
          alert("Copy this link to share: " + window.location.href);
        }
        break;
      case 'Privacy Policy':
        onNavigate('privacy');
        break;
      case 'About ToolsPro':
        onNavigate('about');
        break;
      default:
        break;
    }
  };

  const menuItems = [
    { icon: Star, label: 'Rate Us' },
    { icon: Share2, label: 'Share App' },
    { icon: ShieldCheck, label: 'Privacy Policy' },
    { icon: Info, label: 'About ToolsPro' },
  ];

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          <motion.div 
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
            className="absolute inset-0 bg-black/40 backdrop-blur-sm z-[60]"
          />
          <motion.div 
            initial={{ x: '-100%' }}
            animate={{ x: 0 }}
            exit={{ x: '-100%' }}
            transition={{ type: 'spring', damping: 25, stiffness: 200 }}
            className="absolute top-0 left-0 bottom-0 w-[80%] bg-white z-[70] shadow-2xl flex flex-col transition-colors"
          >
            <div className="p-8 pb-12 pt-16 space-y-6">
              <div className="flex justify-between items-start">
                <div className="space-y-1">
                  <div className="w-14 h-14 bg-primary rounded-2xl flex items-center justify-center text-white font-bold text-xl mb-4 shadow-lg shadow-primary/20">
                    TP
                  </div>
                  <h2 className="text-xl font-bold">ToolsPro</h2>
                  <p className="text-xs text-gray-500 font-medium tracking-wide">Premium Utilities</p>
                </div>
                <button onClick={onClose} className="p-2 bg-gray-50 rounded-full">
                  <X className="w-5 h-5 text-gray-400" />
                </button>
              </div>
            </div>

            <div className="flex-1 px-4 space-y-1 overflow-y-auto">
              {menuItems.map((item, i) => (
                <button 
                  key={i}
                  onClick={() => handleAction(item.label)}
                  className="w-full flex items-center justify-between p-4 rounded-2xl hover:bg-gray-50 transition-colors group"
                >
                  <div className="flex items-center gap-4">
                    <div className="p-2.5 bg-gray-50 rounded-xl group-hover:bg-primary group-hover:text-white transition-all text-gray-500">
                      <item.icon className="w-5 h-5" />
                    </div>
                    <div className="text-left">
                      <p className="text-sm font-bold text-gray-800">{item.label}</p>
                    </div>
                  </div>
                </button>
              ))}
            </div>

            <div 
              onClick={() => {
                onClose();
                onNavigate('about');
              }}
              className="p-8 mt-auto text-center space-y-4 cursor-pointer active:opacity-70 transition-opacity"
            >
               <div className="p-4 bg-primary/5 dark:bg-primary/10 rounded-2xl border border-primary/20">
                  <p className="text-[10px] font-bold text-primary uppercase tracking-widest mb-1">Current Version</p>
                  <p className="text-lg font-black dark:text-white">v4.8.2-PRO</p>
               </div>
               <p className="text-[10px] text-gray-400 font-medium">© 2026 Office ToolsPro Inc.</p>
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
}

interface ProcessingOverlayProps {
  progress: number;
  message: string;
}

export function ProcessingOverlay({ progress, message }: ProcessingOverlayProps) {
  return (
    <div className="absolute inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-8">
      <div className="w-full max-w-sm bg-white dark:bg-gray-900 rounded-3xl p-8 shadow-2xl flex flex-col items-center gap-6 text-center">
        <div className="relative w-20 h-20">
          <svg className="w-full h-full -rotate-90">
             <circle 
               cx="40" cy="40" r="36" 
               className="stroke-gray-100 dark:stroke-gray-800"
               strokeWidth="8" fill="transparent"
             />
             <circle 
               cx="40" cy="40" r="36" 
               className="stroke-primary transition-all duration-300"
               strokeWidth="8" fill="transparent"
               strokeDasharray={226.2}
               strokeDashoffset={226.2 - (226.2 * progress) / 100}
               strokeLinecap="round"
             />
          </svg>
          <div className="absolute inset-0 flex items-center justify-center font-bold text-xl dark:text-white">
            {progress}%
          </div>
        </div>
        <div className="space-y-1">
          <h3 className="font-bold text-lg dark:text-white">{message}</h3>
          <p className="text-sm text-gray-500">Please wait a moment...</p>
        </div>
      </div>
    </div>
  );
}

export function BottomBanner() {
  return (
    <div className="ad-banner">
      Ad Banner Here
    </div>
  );
}
