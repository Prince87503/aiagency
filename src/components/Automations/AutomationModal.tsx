import React, { useState, useEffect } from 'react'
import { X, Plus, Trash2, Zap } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'

interface AutomationModalProps {
  isOpen: boolean
  onClose: () => void
  onSave: (automation: any) => void
  automation?: any
  mode: 'create' | 'edit' | 'view'
}

const TRIGGER_TYPES = [
  'Lead Capture',
  'Course Progress',
  'Payment Event',
  'Calendar Event',
  'Affiliate Event',
  'Form Submission',
  'Time-based'
]

const CATEGORIES = [
  'Lead Nurturing',
  'Student Engagement',
  'Payment Recovery',
  'Demo Management',
  'Affiliate Management',
  'Sales Recovery',
  'Customer Support'
]

const ACTION_OPTIONS = [
  'Send WhatsApp Message',
  'Send Email',
  'Send SMS',
  'Add to Email List',
  'Assign to Sales Team',
  'Generate Certificate',
  'Recommend Next Course',
  'Send SMS Alert',
  'Email Reminder',
  'WhatsApp Follow-up',
  'Pause Access',
  'Update Dashboard',
  'Calculate Commission',
  'Send Notification'
]

export function AutomationModal({ isOpen, onClose, onSave, automation, mode }: AutomationModalProps) {
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    status: 'Draft',
    trigger: '',
    trigger_type: '',
    category: '',
    actions: [] as string[],
    tags: [] as string[],
    created_by: 'Current User'
  })
  const [newAction, setNewAction] = useState('')
  const [newTag, setNewTag] = useState('')

  useEffect(() => {
    if (automation && mode !== 'create') {
      setFormData({
        name: automation.name || '',
        description: automation.description || '',
        status: automation.status || 'Draft',
        trigger: automation.trigger || '',
        trigger_type: automation.triggerType || '',
        category: automation.category || '',
        actions: automation.actions || [],
        tags: automation.tags || [],
        created_by: automation.createdBy || 'Current User'
      })
    } else {
      setFormData({
        name: '',
        description: '',
        status: 'Draft',
        trigger: '',
        trigger_type: '',
        category: '',
        actions: [],
        tags: [],
        created_by: 'Current User'
      })
    }
  }, [automation, mode, isOpen])

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    if (mode === 'view') return

    if (!formData.name.trim()) {
      alert('Please enter an automation name')
      return
    }

    onSave({
      ...formData,
      triggerType: formData.trigger_type
    })
  }

  const addAction = (action: string) => {
    if (action && !formData.actions.includes(action)) {
      setFormData(prev => ({
        ...prev,
        actions: [...prev.actions, action]
      }))
      setNewAction('')
    }
  }

  const removeAction = (action: string) => {
    setFormData(prev => ({
      ...prev,
      actions: prev.actions.filter(a => a !== action)
    }))
  }

  const addTag = () => {
    if (newTag.trim() && !formData.tags.includes(newTag.trim())) {
      setFormData(prev => ({
        ...prev,
        tags: [...prev.tags, newTag.trim()]
      }))
      setNewTag('')
    }
  }

  const removeTag = (tag: string) => {
    setFormData(prev => ({
      ...prev,
      tags: prev.tags.filter(t => t !== tag)
    }))
  }

  if (!isOpen) return null

  const isReadOnly = mode === 'view'

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4 overflow-y-auto">
      <div className="bg-white rounded-lg max-w-3xl w-full max-h-[90vh] overflow-y-auto">
        <div className="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 rounded-lg bg-brand-primary/10 flex items-center justify-center">
              <Zap className="w-5 h-5 text-brand-primary" />
            </div>
            <div>
              <h2 className="text-xl font-bold text-brand-text">
                {mode === 'create' ? 'Create Automation' : mode === 'edit' ? 'Edit Automation' : 'View Automation'}
              </h2>
              <p className="text-sm text-gray-600">
                {mode === 'create' ? 'Build a new workflow automation' : mode === 'edit' ? 'Update automation settings' : 'Automation details'}
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600 transition-colors"
          >
            <X className="w-6 h-6" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Automation Name *
            </label>
            <Input
              type="text"
              value={formData.name}
              onChange={(e) => setFormData(prev => ({ ...prev, name: e.target.value }))}
              placeholder="e.g., Welcome New Leads"
              disabled={isReadOnly}
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Description
            </label>
            <textarea
              value={formData.description}
              onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
              placeholder="Describe what this automation does"
              disabled={isReadOnly}
              rows={3}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-brand-primary disabled:bg-gray-50 disabled:text-gray-600"
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Status
              </label>
              <select
                value={formData.status}
                onChange={(e) => setFormData(prev => ({ ...prev, status: e.target.value }))}
                disabled={isReadOnly}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-brand-primary disabled:bg-gray-50 disabled:text-gray-600"
              >
                <option value="Draft">Draft</option>
                <option value="Active">Active</option>
                <option value="Paused">Paused</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Category
              </label>
              <select
                value={formData.category}
                onChange={(e) => setFormData(prev => ({ ...prev, category: e.target.value }))}
                disabled={isReadOnly}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-brand-primary disabled:bg-gray-50 disabled:text-gray-600"
              >
                <option value="">Select Category</option>
                {CATEGORIES.map(cat => (
                  <option key={cat} value={cat}>{cat}</option>
                ))}
              </select>
            </div>
          </div>

          <div className="border-t border-gray-200 pt-6">
            <h3 className="text-lg font-semibold text-brand-text mb-4">Trigger</h3>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Trigger Type
                </label>
                <select
                  value={formData.trigger_type}
                  onChange={(e) => setFormData(prev => ({ ...prev, trigger_type: e.target.value }))}
                  disabled={isReadOnly}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-brand-primary disabled:bg-gray-50 disabled:text-gray-600"
                >
                  <option value="">Select Trigger Type</option>
                  {TRIGGER_TYPES.map(type => (
                    <option key={type} value={type}>{type}</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Trigger Event
                </label>
                <Input
                  type="text"
                  value={formData.trigger}
                  onChange={(e) => setFormData(prev => ({ ...prev, trigger: e.target.value }))}
                  placeholder="e.g., New Lead Created"
                  disabled={isReadOnly}
                />
              </div>
            </div>
          </div>

          <div className="border-t border-gray-200 pt-6">
            <h3 className="text-lg font-semibold text-brand-text mb-4">Actions</h3>

            {!isReadOnly && (
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Add Action
                </label>
                <div className="flex space-x-2">
                  <select
                    value={newAction}
                    onChange={(e) => setNewAction(e.target.value)}
                    className="flex-1 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-brand-primary"
                  >
                    <option value="">Select an action</option>
                    {ACTION_OPTIONS.map(action => (
                      <option key={action} value={action}>{action}</option>
                    ))}
                  </select>
                  <Button
                    type="button"
                    onClick={() => addAction(newAction)}
                    disabled={!newAction}
                  >
                    <Plus className="w-4 h-4" />
                  </Button>
                </div>
              </div>
            )}

            <div className="space-y-2">
              {formData.actions.length === 0 ? (
                <p className="text-sm text-gray-500">No actions added yet</p>
              ) : (
                formData.actions.map((action, index) => (
                  <div key={action} className="flex items-center justify-between p-3 bg-green-50 border border-green-200 rounded-lg">
                    <div className="flex items-center space-x-3">
                      <span className="text-sm font-medium text-green-800">#{index + 1}</span>
                      <span className="text-sm text-green-900">{action}</span>
                    </div>
                    {!isReadOnly && (
                      <button
                        type="button"
                        onClick={() => removeAction(action)}
                        className="text-red-600 hover:text-red-800"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    )}
                  </div>
                ))
              )}
            </div>
          </div>

          <div className="border-t border-gray-200 pt-6">
            <h3 className="text-lg font-semibold text-brand-text mb-4">Tags</h3>

            {!isReadOnly && (
              <div className="mb-4 flex space-x-2">
                <Input
                  type="text"
                  value={newTag}
                  onChange={(e) => setNewTag(e.target.value)}
                  placeholder="Add a tag"
                  onKeyPress={(e) => {
                    if (e.key === 'Enter') {
                      e.preventDefault()
                      addTag()
                    }
                  }}
                />
                <Button
                  type="button"
                  onClick={addTag}
                  disabled={!newTag.trim()}
                >
                  <Plus className="w-4 h-4" />
                </Button>
              </div>
            )}

            <div className="flex flex-wrap gap-2">
              {formData.tags.length === 0 ? (
                <p className="text-sm text-gray-500">No tags added yet</p>
              ) : (
                formData.tags.map(tag => (
                  <Badge key={tag} variant="outline" className="flex items-center space-x-1">
                    <span>{tag}</span>
                    {!isReadOnly && (
                      <button
                        type="button"
                        onClick={() => removeTag(tag)}
                        className="ml-1 text-gray-500 hover:text-gray-700"
                      >
                        <X className="w-3 h-3" />
                      </button>
                    )}
                  </Badge>
                ))
              )}
            </div>
          </div>

          <div className="border-t border-gray-200 pt-6 flex justify-end space-x-3">
            <Button type="button" variant="outline" onClick={onClose}>
              {isReadOnly ? 'Close' : 'Cancel'}
            </Button>
            {!isReadOnly && (
              <Button type="submit" variant="default">
                {mode === 'create' ? 'Create Automation' : 'Save Changes'}
              </Button>
            )}
          </div>
        </form>
      </div>
    </div>
  )
}
