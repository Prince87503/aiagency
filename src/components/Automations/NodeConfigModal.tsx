import React, { useState, useEffect } from 'react'
import { X, Zap, Play } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { WorkflowNode } from './WorkflowNode'
import { TriggerSelector } from './TriggerSelector'
import { ActionSelector } from './ActionSelector'
import { WebhookActionConfig } from './WebhookActionConfig'

interface NodeConfigModalProps {
  isOpen: boolean
  onClose: () => void
  onSave: (node: WorkflowNode) => void
  node: WorkflowNode | null
  nodeType: 'trigger' | 'action'
  triggerNode?: WorkflowNode | null
}

export function NodeConfigModal({
  isOpen,
  onClose,
  onSave,
  node,
  nodeType,
  triggerNode = null
}: NodeConfigModalProps) {
  const [nodeName, setNodeName] = useState('')
  const [properties, setProperties] = useState<Record<string, any>>({})
  const [showTriggerSelector, setShowTriggerSelector] = useState(false)
  const [showActionSelector, setShowActionSelector] = useState(false)
  const [selectedTrigger, setSelectedTrigger] = useState<any>(null)
  const [selectedAction, setSelectedAction] = useState<any>(null)

  useEffect(() => {
    if (node) {
      setNodeName(node.name)
      setProperties(node.properties || {})
      setSelectedTrigger(node.properties.triggerDefinition || null)
      setSelectedAction(node.properties.actionDefinition || null)
    } else {
      setNodeName('')
      setProperties({})
      setSelectedTrigger(null)
      setSelectedAction(null)
      if (nodeType === 'trigger') {
        setShowTriggerSelector(true)
      } else if (nodeType === 'action') {
        setShowActionSelector(true)
      }
    }
  }, [node, isOpen, nodeType])

  const handleTriggerSelect = (trigger: any) => {
    setSelectedTrigger(trigger)
    setNodeName(trigger.display_name)
    setProperties({
      triggerDefinition: trigger,
      event_name: trigger.event_name,
      event_schema: trigger.event_schema
    })
    setShowTriggerSelector(false)
  }

  const handleActionSelect = (action: any) => {
    setSelectedAction(action)
    setNodeName(action.display_name)

    if (action.action_type === 'webhook') {
      setProperties({
        actionDefinition: action,
        action_type: action.action_type,
        webhook_config: {
          webhook_url: '',
          query_params: [],
          headers: [{ key: 'Content-Type', value: 'application/json' }],
          body: []
        }
      })
    } else {
      setProperties({
        actionDefinition: action,
        action_type: action.action_type
      })
    }
    setShowActionSelector(false)
  }

  const handleSave = () => {
    if (nodeType === 'trigger' && !selectedTrigger) {
      alert('Please select a trigger')
      return
    }

    if (nodeType === 'action' && !selectedAction) {
      alert('Please select an action')
      return
    }

    if (nodeType === 'action' && selectedAction?.action_type === 'webhook') {
      if (!properties.webhook_config?.webhook_url) {
        alert('Please enter a webhook URL')
        return
      }
    }

    if (!nodeName.trim()) {
      alert(`Please enter a ${nodeType} name`)
      return
    }

    const savedNode: WorkflowNode = {
      id: node?.id || `node-${Date.now()}`,
      type: nodeType,
      name: nodeName,
      properties: properties
    }

    onSave(savedNode)
    setShowTriggerSelector(false)
    setShowActionSelector(false)
    onClose()
  }

  const addProperty = () => {
    const key = prompt('Enter property name:')
    if (key && key.trim()) {
      const value = prompt('Enter property value:')
      setProperties(prev => ({
        ...prev,
        [key.trim()]: value || ''
      }))
    }
  }

  const removeProperty = (key: string) => {
    setProperties(prev => {
      const newProps = { ...prev }
      delete newProps[key]
      return newProps
    })
  }

  const updateProperty = (key: string, value: any) => {
    setProperties(prev => ({
      ...prev,
      [key]: value
    }))
  }

  if (!isOpen) return null

  const isTrigger = nodeType === 'trigger'

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-lg max-w-2xl w-full max-h-[90vh] overflow-y-auto">
        <div className="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <div className={`w-10 h-10 rounded-lg flex items-center justify-center ${
              isTrigger ? 'bg-blue-500' : 'bg-green-500'
            }`}>
              {isTrigger ? (
                <Zap className="w-5 h-5 text-white" />
              ) : (
                <Play className="w-5 h-5 text-white" />
              )}
            </div>
            <div>
              <h2 className="text-xl font-bold text-brand-text">
                Configure {isTrigger ? 'Trigger' : 'Action'}
              </h2>
              <p className="text-sm text-gray-600">
                {isTrigger ? 'Define when this workflow should start' : 'Define what action to perform'}
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

        <div className="p-6 space-y-6">
          {isTrigger && showTriggerSelector ? (
            <TriggerSelector
              onSelect={handleTriggerSelect}
              onClose={onClose}
            />
          ) : !isTrigger && showActionSelector ? (
            <ActionSelector
              onSelect={handleActionSelect}
              onClose={onClose}
            />
          ) : (
            <>
              {isTrigger && selectedTrigger && (
                <div className="p-4 bg-blue-50 rounded-lg border border-blue-200">
                  <h4 className="font-semibold text-blue-900 mb-1">Selected Trigger</h4>
                  <p className="text-sm text-blue-700">{selectedTrigger.display_name}</p>
                  <p className="text-xs text-blue-600 mt-1">Event: {selectedTrigger.event_name}</p>
                  <Button
                    type="button"
                    size="sm"
                    variant="outline"
                    onClick={() => setShowTriggerSelector(true)}
                    className="mt-2"
                  >
                    Change Trigger
                  </Button>
                </div>
              )}

              {!isTrigger && selectedAction && (
                <div className="p-4 bg-green-50 rounded-lg border border-green-200">
                  <h4 className="font-semibold text-green-900 mb-1">Selected Action</h4>
                  <p className="text-sm text-green-700">{selectedAction.display_name}</p>
                  <p className="text-xs text-green-600 mt-1">Type: {selectedAction.action_type}</p>
                  <Button
                    type="button"
                    size="sm"
                    variant="outline"
                    onClick={() => setShowActionSelector(true)}
                    className="mt-2"
                  >
                    Change Action
                  </Button>
                </div>
              )}

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  {isTrigger ? 'Trigger' : 'Action'} Name *
                </label>
                <Input
                  type="text"
                  value={nodeName}
                  onChange={(e) => setNodeName(e.target.value)}
                  placeholder={isTrigger ? 'e.g., New Lead Created' : 'e.g., Send Welcome Email'}
                  required
                  disabled={isTrigger && !selectedTrigger}
                />
                <p className="text-xs text-gray-500 mt-1">
                  Give this {nodeType} a descriptive name
                </p>
              </div>

              {!isTrigger && selectedAction?.action_type === 'webhook' && (
                <div className="border-t border-gray-200 pt-6">
                  <h3 className="text-lg font-semibold text-brand-text mb-4">Webhook Configuration</h3>
                  <WebhookActionConfig
                    config={properties.webhook_config || {
                      webhook_url: '',
                      query_params: [],
                      headers: [{ key: 'Content-Type', value: 'application/json' }],
                      body: []
                    }}
                    onChange={(config) => setProperties(prev => ({ ...prev, webhook_config: config }))}
                    triggerSchema={triggerNode?.properties?.event_schema || []}
                  />
                </div>
              )}

              <div className="border-t border-gray-200 pt-6 flex justify-end space-x-3">
                <Button type="button" variant="outline" onClick={onClose}>
                  Cancel
                </Button>
                <Button type="button" variant="default" onClick={handleSave}>
                  Save {isTrigger ? 'Trigger' : 'Action'}
                </Button>
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  )
}
