import React from 'react'
import { Plus, X, Settings, Zap, Play } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'

export interface WorkflowNode {
  id: string
  type: 'trigger' | 'action'
  name: string
  properties: Record<string, any>
  position?: { x: number; y: number }
}

interface WorkflowNodeProps {
  node: WorkflowNode
  onEdit: (node: WorkflowNode) => void
  onDelete: (nodeId: string) => void
  isFirst?: boolean
  isLast?: boolean
  isReadOnly?: boolean
}

export function WorkflowNodeComponent({
  node,
  onEdit,
  onDelete,
  isFirst = false,
  isLast = false,
  isReadOnly = false
}: WorkflowNodeProps) {
  const isTrigger = node.type === 'trigger'

  return (
    <div className="flex flex-col items-center">
      <div
        className={`relative w-full max-w-md border-2 rounded-lg p-4 transition-all hover:shadow-lg ${
          isTrigger
            ? 'border-blue-400 bg-blue-50'
            : 'border-green-400 bg-green-50'
        }`}
      >
        <div className="flex items-start justify-between mb-3">
          <div className="flex items-center space-x-2">
            <div className={`w-8 h-8 rounded-full flex items-center justify-center ${
              isTrigger ? 'bg-blue-500' : 'bg-green-500'
            }`}>
              {isTrigger ? (
                <Zap className="w-4 h-4 text-white" />
              ) : (
                <Play className="w-4 h-4 text-white" />
              )}
            </div>
            <div>
              <Badge variant="outline" className={
                isTrigger ? 'bg-blue-100 text-blue-800' : 'bg-green-100 text-green-800'
              }>
                {isTrigger ? 'Trigger' : 'Action'}
              </Badge>
            </div>
          </div>
          {!isReadOnly && (
            <div className="flex items-center space-x-1">
              <Button
                size="sm"
                variant="ghost"
                onClick={() => onEdit(node)}
                className="h-8 w-8 p-0"
              >
                <Settings className="w-4 h-4" />
              </Button>
              {!isTrigger && (
                <Button
                  size="sm"
                  variant="ghost"
                  onClick={() => onDelete(node.id)}
                  className="h-8 w-8 p-0 text-red-600 hover:text-red-700 hover:bg-red-50"
                >
                  <X className="w-4 h-4" />
                </Button>
              )}
            </div>
          )}
        </div>

        <h3 className={`font-semibold text-lg mb-2 ${
          isTrigger ? 'text-blue-900' : 'text-green-900'
        }`}>
          {node.name || (isTrigger ? 'Configure Trigger' : 'Configure Action')}
        </h3>

        {node.type === 'trigger' && node.properties.triggerDefinition && (
          <div className="mt-3 space-y-2">
            <div className="text-sm">
              <span className="text-gray-600">Event:</span>
              <span className="ml-2 text-gray-900 font-medium font-mono text-xs">
                {node.properties.event_name}
              </span>
            </div>
            {node.properties.event_schema && (
              <div className="text-xs text-gray-500">
                {node.properties.event_schema.length} data fields available
              </div>
            )}
          </div>
        )}

        {node.type === 'action' && node.properties.actionDefinition && (
          <div className="mt-3 space-y-2">
            <div className="text-sm">
              <span className="text-gray-600">Type:</span>
              <span className="ml-2 text-gray-900 font-medium">
                {node.properties.action_type}
              </span>
            </div>
            {node.properties.action_type === 'webhook' && node.properties.webhook_config && (
              <>
                <div className="text-xs">
                  <span className="text-gray-600">URL:</span>
                  <span className="ml-2 text-gray-900 font-mono truncate block">
                    {node.properties.webhook_config.webhook_url || 'Not configured'}
                  </span>
                </div>
                <div className="text-xs text-gray-500">
                  {node.properties.webhook_config.body?.length || 0} body parameters configured
                </div>
              </>
            )}
          </div>
        )}

        {Object.keys(node.properties).length === 0 && (
          <p className="text-sm text-gray-500 italic">
            No properties configured yet
          </p>
        )}
      </div>

      {!isLast && (
        <div className="flex flex-col items-center my-2">
          <div className="w-0.5 h-8 bg-gray-300"></div>
          <div className="w-2 h-2 rounded-full bg-gray-300"></div>
          <div className="w-0.5 h-8 bg-gray-300"></div>
        </div>
      )}
    </div>
  )
}
