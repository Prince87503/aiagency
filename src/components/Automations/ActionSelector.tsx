import React, { useState, useEffect } from 'react'
import { supabase } from '@/lib/supabase'
import { Search, Play, Globe, Mail, MessageCircle, Phone, Send, Bell } from 'lucide-react'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'

interface ActionDefinition {
  id: string
  name: string
  display_name: string
  description: string
  action_type: string
  config_schema: any
  category: string
  icon: string
}

interface ActionSelectorProps {
  onSelect: (action: ActionDefinition) => void
  onClose: () => void
}

const iconMap: Record<string, any> = {
  'globe': Globe,
  'mail': Mail,
  'message-circle': MessageCircle,
  'phone': Phone,
  'send': Send,
  'bell': Bell,
  'play': Play
}

export function ActionSelector({ onSelect, onClose }: ActionSelectorProps) {
  const [actions, setActions] = useState<ActionDefinition[]>([])
  const [searchTerm, setSearchTerm] = useState('')
  const [loading, setLoading] = useState(true)
  const [selectedCategory, setSelectedCategory] = useState<string>('All')

  useEffect(() => {
    fetchActions()
  }, [])

  const fetchActions = async () => {
    try {
      const { data, error } = await supabase
        .from('workflow_actions')
        .select('*')
        .eq('is_active', true)
        .order('category', { ascending: true })

      if (error) throw error
      setActions(data || [])
    } catch (error) {
      console.error('Error fetching actions:', error)
    } finally {
      setLoading(false)
    }
  }

  const categories = ['All', ...Array.from(new Set(actions.map(a => a.category)))]

  const filteredActions = actions.filter(action => {
    const matchesSearch =
      action.display_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      action.description?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      action.action_type.toLowerCase().includes(searchTerm.toLowerCase())

    const matchesCategory = selectedCategory === 'All' || action.category === selectedCategory

    return matchesSearch && matchesCategory
  })

  return (
    <div className="space-y-4">
      <div>
        <h3 className="text-lg font-semibold text-brand-text mb-2">Select an Action</h3>
        <p className="text-sm text-gray-600 mb-4">
          Choose what action should be performed when this workflow runs
        </p>
      </div>

      <div className="relative">
        <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
        <Input
          type="text"
          placeholder="Search actions..."
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
        <div className="text-center py-8 text-gray-500">Loading actions...</div>
      ) : filteredActions.length === 0 ? (
        <div className="text-center py-8 text-gray-500">No actions found</div>
      ) : (
        <div className="grid grid-cols-1 gap-3 max-h-96 overflow-y-auto">
          {filteredActions.map(action => {
            const IconComponent = iconMap[action.icon] || Play
            return (
              <button
                key={action.id}
                onClick={() => onSelect(action)}
                className="flex items-start space-x-3 p-4 border border-gray-200 rounded-lg hover:border-brand-primary hover:bg-brand-primary/5 transition-all text-left"
              >
                <div className="w-10 h-10 rounded-lg bg-green-100 flex items-center justify-center flex-shrink-0">
                  <IconComponent className="w-5 h-5 text-green-600" />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center space-x-2 mb-1">
                    <h4 className="font-semibold text-brand-text">{action.display_name}</h4>
                    <span className="text-xs px-2 py-0.5 rounded-full bg-green-100 text-green-800">
                      {action.category}
                    </span>
                  </div>
                  <p className="text-sm text-gray-600 mb-1">{action.description}</p>
                  <p className="text-xs text-gray-500">Type: {action.action_type}</p>
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
