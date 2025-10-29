import React, { useState, useEffect } from 'react'
import { supabase } from '@/lib/supabase'
import { Search, Zap, Users, Mail, Calendar, CreditCard, Award, BookOpen } from 'lucide-react'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'

interface TriggerDefinition {
  id: string
  name: string
  display_name: string
  description: string
  event_name: string
  event_schema: any[]
  category: string
  icon: string
}

interface TriggerSelectorProps {
  onSelect: (trigger: TriggerDefinition) => void
  onClose: () => void
}

const iconMap: Record<string, any> = {
  'users': Users,
  'mail': Mail,
  'calendar': Calendar,
  'credit-card': CreditCard,
  'award': Award,
  'book-open': BookOpen,
  'zap': Zap
}

export function TriggerSelector({ onSelect, onClose }: TriggerSelectorProps) {
  const [triggers, setTriggers] = useState<TriggerDefinition[]>([])
  const [searchTerm, setSearchTerm] = useState('')
  const [loading, setLoading] = useState(true)
  const [selectedCategory, setSelectedCategory] = useState<string>('All')

  useEffect(() => {
    fetchTriggers()
  }, [])

  const fetchTriggers = async () => {
    try {
      const { data, error } = await supabase
        .from('workflow_triggers')
        .select('*')
        .eq('is_active', true)
        .order('category', { ascending: true })

      if (error) throw error
      setTriggers(data || [])
    } catch (error) {
      console.error('Error fetching triggers:', error)
    } finally {
      setLoading(false)
    }
  }

  const categories = ['All', ...Array.from(new Set(triggers.map(t => t.category)))]

  const filteredTriggers = triggers.filter(trigger => {
    const matchesSearch =
      trigger.display_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      trigger.description?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      trigger.event_name.toLowerCase().includes(searchTerm.toLowerCase())

    const matchesCategory = selectedCategory === 'All' || trigger.category === selectedCategory

    return matchesSearch && matchesCategory
  })

  return (
    <div className="space-y-4">
      <div>
        <h3 className="text-lg font-semibold text-brand-text mb-2">Select a Trigger</h3>
        <p className="text-sm text-gray-600 mb-4">
          Choose what event should start this workflow
        </p>
      </div>

      <div className="relative">
        <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
        <Input
          type="text"
          placeholder="Search triggers..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="pl-10"
        />
      </div>

      <div className="flex flex-wrap gap-2">
        {categories.map(category => (
          <button
            key={category}
            onClick={() => setSelectedCategory(category)}
            className={`px-3 py-1 rounded-full text-sm transition-colors ${
              selectedCategory === category
                ? 'bg-brand-primary text-white'
                : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            }`}
          >
            {category}
          </button>
        ))}
      </div>

      {loading ? (
        <div className="text-center py-8 text-gray-500">Loading triggers...</div>
      ) : filteredTriggers.length === 0 ? (
        <div className="text-center py-8 text-gray-500">No triggers found</div>
      ) : (
        <div className="grid grid-cols-1 gap-3 max-h-96 overflow-y-auto">
          {filteredTriggers.map(trigger => {
            const IconComponent = iconMap[trigger.icon] || Zap
            return (
              <button
                key={trigger.id}
                onClick={() => onSelect(trigger)}
                className="flex items-start space-x-3 p-4 border border-gray-200 rounded-lg hover:border-brand-primary hover:bg-brand-primary/5 transition-all text-left"
              >
                <div className="w-10 h-10 rounded-lg bg-blue-100 flex items-center justify-center flex-shrink-0">
                  <IconComponent className="w-5 h-5 text-blue-600" />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center space-x-2 mb-1">
                    <h4 className="font-semibold text-brand-text">{trigger.display_name}</h4>
                    <span className="text-xs px-2 py-0.5 rounded-full bg-blue-100 text-blue-800">
                      {trigger.category}
                    </span>
                  </div>
                  <p className="text-sm text-gray-600 mb-1">{trigger.description}</p>
                  <p className="text-xs text-gray-500 font-mono">Event: {trigger.event_name}</p>
                  <p className="text-xs text-gray-400 mt-1">
                    {trigger.event_schema?.length || 0} data fields available
                  </p>
                </div>
              </button>
            )
          })}
        </div>
      )}

      <div className="flex justify-end pt-4 border-t border-gray-200">
        <Button type="button" variant="outline" onClick={onClose}>
          Cancel
        </Button>
      </div>
    </div>
  )
}
