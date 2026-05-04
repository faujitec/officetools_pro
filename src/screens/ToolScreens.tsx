import React from 'react';
import { motion } from 'motion/react';
import { MAIN_TOOLS } from '../constants';
import { Header, BottomBanner } from '../components/CommonUI';
import { Screen } from '../types';
import { ChevronRight } from 'lucide-react';

interface ScreenProps {
  onNavigate: (screen: Screen, toolId?: string) => void;
  onMenu: () => void;
}

export function Home({ onNavigate, onMenu }: ScreenProps) {
  return (
    <div className="iphone-vibe h-screen">
      <Header 
        title="Office ToolsPro" 
        showSearch 
        onMenu={onMenu}
      />
      
      <div className="flex-1 overflow-y-auto px-6 py-4">
        <div className="grid grid-cols-2 gap-4">
          {MAIN_TOOLS.map((tool) => (
            <motion.button
              key={tool.id}
              whileTap={{ scale: 0.95 }}
              onClick={() => tool.screen && onNavigate(tool.screen as Screen, tool.id)}
              className="p-6 bg-white rounded-3xl shadow-sm border border-gray-100 flex flex-col items-center gap-3 transition-colors"
            >
              <div className={`p-3 rounded-2xl ${tool.color}`}>
                <tool.icon className="w-8 h-8" />
              </div>
              <span className="text-sm font-semibold">{tool.name}</span>
            </motion.button>
          ))}
        </div>
      </div>
      
      <BottomBanner />
    </div>
  );
}

export function ToolListScreen({ 
  title, 
  tools, 
  onBack, 
  onNavigate 
}: { 
  title: string, 
  tools: any[], 
  onBack: () => void,
  onNavigate: (screen: Screen, toolId?: string) => void
}) {
  return (
    <div className="iphone-vibe h-screen">
      <Header title={title} onBack={onBack} />
      
      <div className="flex-1 overflow-y-auto px-6 py-4 space-y-3">
        {tools.map((tool) => (
          <motion.button
            key={tool.id}
            whileTap={{ scale: 0.98 }}
            onClick={() => tool.screen && onNavigate(tool.screen, tool.id)}
            className="w-full p-4 bg-white rounded-2xl shadow-sm border border-gray-100 flex items-center justify-between transition-colors"
          >
            <div className="flex items-center gap-4">
              <div className="p-2 bg-blue-50 rounded-xl text-blue-600">
                <tool.icon className="w-6 h-6" />
              </div>
              <span className="font-semibold text-gray-800">{tool.name}</span>
            </div>
            <ChevronRight className="w-5 h-5 text-gray-400" />
          </motion.button>
        ))}
      </div>
      
      <BottomBanner />
    </div>
  );
}
