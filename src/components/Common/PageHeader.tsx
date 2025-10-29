import React from 'react'
import { motion } from 'framer-motion'
import { Button } from '@/components/ui/button'

interface PageHeaderProps {
  title: string
  subtitle?: string
  actions?: Array<{
    label: string
    onClick: () => void
    variant?: 'default' | 'secondary' | 'outline'
    icon?: React.ComponentType<any>
  }>
}

export function PageHeader({ title, subtitle, actions = [] }: PageHeaderProps) {
  return (
    <motion.div
      initial={{ opacity: 0, y: -20 }}
      animate={{ opacity: 1, y: 0 }}
      className="mb-8"
    >
      {/* Background Pattern */}
      <div className="absolute inset-0 dots-bg pointer-events-none" />
      
      <div className="relative bg-white rounded-2xl shadow-xl border border-gray-100 p-8">
        <div className="flex items-center justify-between">
          <div>
            <motion.h1 
              className="text-4xl font-bold text-brand-text mb-2"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.1 }}
            >
              {title}
            </motion.h1>
            {subtitle && (
              <motion.p 
                className="text-lg text-gray-600"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ delay: 0.2 }}
              >
                {subtitle}
              </motion.p>
            )}
          </div>
          
          {actions.length > 0 && (
            <motion.div 
              className="flex items-center space-x-3"
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.3 }}
            >
              {actions.map((action, index) => {
                const Icon = action.icon
                return (
                  <Button
                    key={index}
                    onClick={action.onClick}
                    variant={action.variant || 'default'}
                    className="shadow-lg hover:shadow-xl transition-shadow"
                  >
                    {Icon && <Icon className="w-4 h-4 mr-2" />}
                    {action.label}
                  </Button>
                )
              })}
            </motion.div>
          )}
        </div>
      </div>
    </motion.div>
  )
}