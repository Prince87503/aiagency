import React, { createContext, useContext, useState, useEffect } from 'react'
import { supabase } from '@/lib/supabase'

export type KPICategory = 'primary' | 'success' | 'warning' | 'secondary'

export interface AppearanceSettings {
  primary_color: string
  success_color: string
  warning_color: string
  secondary_color: string
}

interface AppearanceContextType {
  settings: AppearanceSettings
  loading: boolean
  updateSettings: (settings: AppearanceSettings) => Promise<void>
  getCategoryColor: (category: KPICategory) => string
}

const defaultSettings: AppearanceSettings = {
  primary_color: 'blue',
  success_color: 'green',
  warning_color: 'orange',
  secondary_color: 'purple'
}

const AppearanceContext = createContext<AppearanceContextType>({
  settings: defaultSettings,
  loading: true,
  updateSettings: async () => {},
  getCategoryColor: () => 'blue'
})

export function AppearanceProvider({ children }: { children: React.ReactNode }) {
  const [settings, setSettings] = useState<AppearanceSettings>(defaultSettings)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    loadSettings()
  }, [])

  const loadSettings = async () => {
    try {
      const { data, error } = await supabase
        .from('appearance_settings')
        .select('*')
        .is('user_id', null)
        .maybeSingle()

      if (error) throw error

      if (data) {
        setSettings({
          primary_color: data.primary_color,
          success_color: data.success_color,
          warning_color: data.warning_color,
          secondary_color: data.secondary_color
        })
      }
    } catch (error) {
      console.error('Error loading appearance settings:', error)
    } finally {
      setLoading(false)
    }
  }

  const updateSettings = async (newSettings: AppearanceSettings) => {
    try {
      const { error } = await supabase
        .from('appearance_settings')
        .update({
          primary_color: newSettings.primary_color,
          success_color: newSettings.success_color,
          warning_color: newSettings.warning_color,
          secondary_color: newSettings.secondary_color,
          updated_at: new Date().toISOString()
        })
        .is('user_id', null)

      if (error) throw error

      setSettings(newSettings)
    } catch (error) {
      console.error('Error updating appearance settings:', error)
      throw error
    }
  }

  const getCategoryColor = (category: KPICategory): string => {
    switch (category) {
      case 'primary':
        return settings.primary_color
      case 'success':
        return settings.success_color
      case 'warning':
        return settings.warning_color
      case 'secondary':
        return settings.secondary_color
      default:
        return 'blue'
    }
  }

  return (
    <AppearanceContext.Provider value={{ settings, loading, updateSettings, getCategoryColor }}>
      {children}
    </AppearanceContext.Provider>
  )
}

export function useAppearance() {
  const context = useContext(AppearanceContext)
  if (!context) {
    throw new Error('useAppearance must be used within AppearanceProvider')
  }
  return context
}
