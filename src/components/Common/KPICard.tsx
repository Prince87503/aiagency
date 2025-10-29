import React from 'react'
import { motion } from 'framer-motion'
import { TrendingUp, TrendingDown } from 'lucide-react'
import { Card, CardContent } from '@/components/ui/card'
import { useAppearance, type KPICategory } from '@/contexts/AppearanceContext'

interface KPICardProps {
  title: string
  value: string | number
  change?: number
  variant?: 'primary' | 'accent' | 'surface'
  icon?: React.ComponentType<any>
  trend?: 'up' | 'down' | 'neutral'
  colorScheme?: 'blue' | 'green' | 'orange' | 'purple' | 'red' | 'pink' | 'teal' | 'cyan' | 'indigo' | 'black' | 'default'
  category?: KPICategory
}

export function KPICard({ title, value, change, variant = 'surface', icon: Icon, trend, colorScheme = 'default', category }: KPICardProps) {
  const { getCategoryColor } = useAppearance()

  const getColorSchemeStyles = () => {
    let effectiveColor = colorScheme

    if (category) {
      effectiveColor = getCategoryColor(category) as any
    }

    switch (effectiveColor) {
      case 'blue':
        return 'bg-gradient-to-br from-blue-500 to-blue-600 text-white'
      case 'green':
        return 'bg-gradient-to-br from-green-500 to-green-600 text-white'
      case 'orange':
        return 'bg-gradient-to-br from-orange-500 to-orange-600 text-white'
      case 'purple':
        return 'bg-gradient-to-br from-purple-500 to-purple-600 text-white'
      case 'red':
        return 'bg-gradient-to-br from-red-500 to-red-600 text-white'
      case 'pink':
        return 'bg-gradient-to-br from-pink-500 to-pink-600 text-white'
      case 'teal':
        return 'bg-gradient-to-br from-teal-500 to-teal-600 text-white'
      case 'cyan':
        return 'bg-gradient-to-br from-cyan-500 to-cyan-600 text-white'
      case 'indigo':
        return 'bg-gradient-to-br from-indigo-500 to-indigo-600 text-white'
      case 'black':
        return 'bg-gradient-to-br from-gray-900 to-gray-800 text-white'
      default:
        switch (variant) {
          case 'primary':
            return 'bg-gradient-to-br from-brand-primary to-brand-primary/80 text-white'
          case 'accent':
            return 'bg-gradient-to-br from-brand-accent to-brand-accent/80 text-white'
          default:
            return 'bg-white border border-gray-100'
        }
    }
  }

  const isColoredCard = colorScheme !== 'default' || category !== undefined
  const hasWhiteText = isColoredCard || variant === 'primary' || variant === 'accent'

  return (
    <motion.div
      whileHover={{ scale: 1.02 }}
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className="h-full"
    >
      <Card className={`shadow-xl hover:shadow-2xl transition-all duration-300 ${getColorSchemeStyles()}`}>
        <CardContent className="p-6">
          <div className="flex flex-col gap-3">
            <p className={`text-sm font-medium ${hasWhiteText ? 'text-white/90' : 'text-gray-600'}`}>
              {title}
            </p>
            <div className="flex items-center justify-between">
              <div className="flex flex-col">
                <p className={`text-4xl font-bold ${hasWhiteText ? 'text-white' : 'text-brand-text'}`}>
                  {value}
                </p>
                {change !== undefined && (
                  <div className="flex items-center mt-2">
                    {change > 0 ? (
                      <TrendingUp className={`w-4 h-4 mr-1 ${hasWhiteText ? 'text-white/80' : 'text-green-500'}`} />
                    ) : (
                      <TrendingDown className={`w-4 h-4 mr-1 ${hasWhiteText ? 'text-white/80' : 'text-red-500'}`} />
                    )}
                    <span className={`text-sm font-medium ${hasWhiteText ? 'text-white/80' : (change > 0 ? 'text-green-500' : 'text-red-500')}`}>
                      {Math.abs(change)}%
                    </span>
                  </div>
                )}
              </div>
              {Icon && (
                <div className={`p-3 rounded-xl ${hasWhiteText ? 'bg-white/20' : 'bg-brand-primary/10'}`}>
                  <Icon className={`w-8 h-8 ${hasWhiteText ? 'text-white' : 'text-brand-primary'}`} />
                </div>
              )}
            </div>
          </div>
        </CardContent>
      </Card>
    </motion.div>
  )
}