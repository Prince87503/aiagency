import React, { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { Palette, Save, RotateCcw } from 'lucide-react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { useAppearance } from '@/contexts/AppearanceContext'

const colorOptions = [
  { value: 'blue', label: 'Blue', class: 'bg-blue-500' },
  { value: 'green', label: 'Green', class: 'bg-green-500' },
  { value: 'orange', label: 'Orange', class: 'bg-orange-500' },
  { value: 'purple', label: 'Purple', class: 'bg-purple-500' },
  { value: 'red', label: 'Red', class: 'bg-red-500' },
  { value: 'pink', label: 'Pink', class: 'bg-pink-500' },
  { value: 'teal', label: 'Teal', class: 'bg-teal-500' },
  { value: 'cyan', label: 'Cyan', class: 'bg-cyan-500' },
  { value: 'indigo', label: 'Indigo', class: 'bg-indigo-500' },
  { value: 'black', label: 'Black', class: 'bg-gray-900' }
]

const categoryDescriptions = {
  primary: {
    title: 'Primary/Total Metrics',
    description: 'Colors for total counts, primary metrics, and main statistics',
    examples: 'Total Leads, Total Members, Total Products, Total Revenue'
  },
  success: {
    title: 'Success/Revenue/Active Metrics',
    description: 'Colors for positive metrics, revenue, active items, and success indicators',
    examples: 'Active Members, Revenue, Earnings Paid, Approved, Present Today'
  },
  warning: {
    title: 'Warning/Pending Metrics',
    description: 'Colors for pending items, warnings, and items requiring attention',
    examples: 'Pending Approval, Late Today, Overdue Amount, Open Tickets'
  },
  secondary: {
    title: 'Secondary/Category Metrics',
    description: 'Colors for secondary information, categories, and supplementary data',
    examples: 'Departments, Course Students, Referrals, Categories'
  }
}

export function AppearanceSettings() {
  const { settings, updateSettings } = useAppearance()
  const [localSettings, setLocalSettings] = useState(settings)
  const [saving, setSaving] = useState(false)
  const [message, setMessage] = useState('')

  useEffect(() => {
    setLocalSettings(settings)
  }, [settings])

  const handleColorChange = (category: keyof typeof settings, color: string) => {
    setLocalSettings(prev => ({
      ...prev,
      [`${category}_color`]: color
    }))
  }

  const handleSave = async () => {
    setSaving(true)
    setMessage('')
    try {
      await updateSettings(localSettings)
      setMessage('Appearance settings saved successfully!')
      setTimeout(() => setMessage(''), 3000)
    } catch (error) {
      setMessage('Failed to save settings. Please try again.')
      setTimeout(() => setMessage(''), 3000)
    } finally {
      setSaving(false)
    }
  }

  const handleReset = () => {
    const defaultSettings = {
      primary_color: 'blue',
      success_color: 'green',
      warning_color: 'orange',
      secondary_color: 'purple'
    }
    setLocalSettings(defaultSettings)
  }

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <Palette className="w-6 h-6 text-brand-primary" />
              <div>
                <CardTitle>KPI Card Colors</CardTitle>
                <p className="text-sm text-gray-600 mt-1">
                  Customize the colors for different categories of KPI cards across the dashboard
                </p>
              </div>
            </div>
          </div>
        </CardHeader>
        <CardContent className="space-y-6">
          {Object.entries(categoryDescriptions).map(([key, info]) => {
            const categoryKey = `${key}_color` as keyof typeof localSettings
            const currentColor = localSettings[categoryKey]

            return (
              <motion.div
                key={key}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                className="border rounded-lg p-6 bg-gray-50"
              >
                <div className="mb-4">
                  <h3 className="font-semibold text-lg mb-2">{info.title}</h3>
                  <p className="text-sm text-gray-600 mb-2">{info.description}</p>
                  <p className="text-xs text-gray-500 italic">Examples: {info.examples}</p>
                </div>

                <div>
                  <span className="text-sm font-medium text-gray-700 mb-3 block">Select Color:</span>
                  <div className="grid grid-cols-5 md:grid-cols-10 gap-3">
                    {colorOptions.map(color => (
                      <button
                        key={color.value}
                        onClick={() => handleColorChange(key as any, color.value)}
                        className={`relative w-16 h-16 rounded-lg ${color.class} transition-all hover:scale-110 shadow-md ${
                          currentColor === color.value
                            ? 'ring-4 ring-brand-primary ring-offset-2 shadow-lg scale-110'
                            : 'opacity-80 hover:opacity-100'
                        }`}
                        title={color.label}
                      >
                        {currentColor === color.value && (
                          <div className="absolute inset-0 flex items-center justify-center">
                            <div className="w-7 h-7 bg-white rounded-full flex items-center justify-center shadow-lg">
                              <div className="w-4 h-4 bg-brand-primary rounded-full" />
                            </div>
                          </div>
                        )}
                      </button>
                    ))}
                  </div>
                  <span className="mt-3 text-sm font-semibold text-brand-primary capitalize block">
                    Selected: {currentColor}
                  </span>
                </div>
              </motion.div>
            )
          })}

          {message && (
            <motion.div
              initial={{ opacity: 0, y: -10 }}
              animate={{ opacity: 1, y: 0 }}
              className={`p-4 rounded-lg ${
                message.includes('success')
                  ? 'bg-green-50 text-green-800 border border-green-200'
                  : 'bg-red-50 text-red-800 border border-red-200'
              }`}
            >
              {message}
            </motion.div>
          )}

          <div className="flex gap-3 pt-4 border-t">
            <Button
              onClick={handleSave}
              disabled={saving}
              className="flex items-center gap-2"
            >
              <Save className="w-4 h-4" />
              {saving ? 'Saving...' : 'Save Changes'}
            </Button>
            <Button
              onClick={handleReset}
              variant="outline"
              className="flex items-center gap-2"
            >
              <RotateCcw className="w-4 h-4" />
              Reset to Default
            </Button>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Preview</CardTitle>
          <p className="text-sm text-gray-600">See how your KPI cards will look with the selected colors</p>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            {Object.entries(categoryDescriptions).map(([key, info]) => {
              const categoryKey = `${key}_color` as keyof typeof localSettings
              const currentColor = localSettings[categoryKey]
              const colorClass = colorOptions.find(c => c.value === currentColor)?.class || 'bg-blue-500'

              return (
                <div key={key} className={`${colorClass} rounded-lg p-6 text-white shadow-xl`}>
                  <div className="bg-white/20 p-3 rounded-lg w-fit mb-4">
                    <Palette className="w-6 h-6" />
                  </div>
                  <p className="text-sm font-medium opacity-90 mb-2">{info.title.split('/')[0]}</p>
                  <p className="text-3xl font-bold">1,234</p>
                </div>
              )
            })}
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
