import React, { useState, useEffect } from 'react'
import { Plus, X, ChevronDown, ChevronUp } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'

interface KeyValuePair {
  key: string
  value: string
}

interface WebhookConfig {
  webhook_url: string
  query_params: KeyValuePair[]
  headers: KeyValuePair[]
  body: KeyValuePair[]
}

interface WebhookActionConfigProps {
  config: WebhookConfig
  onChange: (config: WebhookConfig) => void
  triggerSchema?: any[]
}

export function WebhookActionConfig({ config, onChange, triggerSchema = [] }: WebhookActionConfigProps) {
  const [expandedSections, setExpandedSections] = useState({
    queryParams: false,
    headers: true,
    body: true
  })

  const handleUrlChange = (url: string) => {
    onChange({ ...config, webhook_url: url })
  }

  const addKeyValuePair = (field: 'query_params' | 'headers' | 'body') => {
    onChange({
      ...config,
      [field]: [...config[field], { key: '', value: '' }]
    })
  }

  const updateKeyValuePair = (
    field: 'query_params' | 'headers' | 'body',
    index: number,
    key: string,
    value: string
  ) => {
    const updated = [...config[field]]
    updated[index] = { key, value }
    onChange({ ...config, [field]: updated })
  }

  const removeKeyValuePair = (field: 'query_params' | 'headers' | 'body', index: number) => {
    onChange({
      ...config,
      [field]: config[field].filter((_, i) => i !== index)
    })
  }

  const toggleSection = (section: keyof typeof expandedSections) => {
    setExpandedSections(prev => ({ ...prev, [section]: !prev[section] }))
  }

  const insertTriggerField = (field: 'query_params' | 'headers' | 'body', index: number, triggerField: string) => {
    const updated = [...config[field]]
    updated[index] = { ...updated[index], value: `{{${triggerField}}}` }
    onChange({ ...config, [field]: updated })
  }

  return (
    <div className="space-y-4">
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-2">
          Webhook URL *
        </label>
        <Input
          type="url"
          value={config.webhook_url}
          onChange={(e) => handleUrlChange(e.target.value)}
          placeholder="https://example.com/webhook"
          required
        />
        <p className="text-xs text-gray-500 mt-1">
          The URL where the POST request will be sent
        </p>
      </div>

      <div className="border rounded-lg">
        <button
          type="button"
          onClick={() => toggleSection('queryParams')}
          className="w-full flex items-center justify-between p-3 hover:bg-gray-50"
        >
          <span className="font-medium text-gray-900">Query Parameters</span>
          {expandedSections.queryParams ? (
            <ChevronUp className="w-4 h-4 text-gray-500" />
          ) : (
            <ChevronDown className="w-4 h-4 text-gray-500" />
          )}
        </button>
        {expandedSections.queryParams && (
          <div className="p-3 border-t space-y-2">
            {config.query_params.length === 0 ? (
              <p className="text-sm text-gray-500 text-center py-2">No query parameters added</p>
            ) : (
              config.query_params.map((param, index) => (
                <div key={index} className="flex items-start space-x-2">
                  <Input
                    type="text"
                    value={param.key}
                    onChange={(e) => updateKeyValuePair('query_params', index, e.target.value, param.value)}
                    placeholder="Key"
                    className="flex-1"
                  />
                  <Input
                    type="text"
                    value={param.value}
                    onChange={(e) => updateKeyValuePair('query_params', index, param.key, e.target.value)}
                    placeholder="Value"
                    className="flex-1"
                  />
                  <Button
                    type="button"
                    size="sm"
                    variant="ghost"
                    onClick={() => removeKeyValuePair('query_params', index)}
                    className="text-red-600 hover:text-red-700"
                  >
                    <X className="w-4 h-4" />
                  </Button>
                </div>
              ))
            )}
            <Button
              type="button"
              size="sm"
              variant="outline"
              onClick={() => addKeyValuePair('query_params')}
              className="w-full"
            >
              <Plus className="w-4 h-4 mr-2" />
              Add Query Parameter
            </Button>
          </div>
        )}
      </div>

      <div className="border rounded-lg">
        <button
          type="button"
          onClick={() => toggleSection('headers')}
          className="w-full flex items-center justify-between p-3 hover:bg-gray-50"
        >
          <span className="font-medium text-gray-900">Headers</span>
          {expandedSections.headers ? (
            <ChevronUp className="w-4 h-4 text-gray-500" />
          ) : (
            <ChevronDown className="w-4 h-4 text-gray-500" />
          )}
        </button>
        {expandedSections.headers && (
          <div className="p-3 border-t space-y-2">
            {config.headers.length === 0 ? (
              <p className="text-sm text-gray-500 text-center py-2">No headers added</p>
            ) : (
              config.headers.map((header, index) => (
                <div key={index} className="flex items-start space-x-2">
                  <Input
                    type="text"
                    value={header.key}
                    onChange={(e) => updateKeyValuePair('headers', index, e.target.value, header.value)}
                    placeholder="Header Name"
                    className="flex-1"
                  />
                  <Input
                    type="text"
                    value={header.value}
                    onChange={(e) => updateKeyValuePair('headers', index, header.key, e.target.value)}
                    placeholder="Header Value"
                    className="flex-1"
                  />
                  <Button
                    type="button"
                    size="sm"
                    variant="ghost"
                    onClick={() => removeKeyValuePair('headers', index)}
                    className="text-red-600 hover:text-red-700"
                  >
                    <X className="w-4 h-4" />
                  </Button>
                </div>
              ))
            )}
            <Button
              type="button"
              size="sm"
              variant="outline"
              onClick={() => addKeyValuePair('headers')}
              className="w-full"
            >
              <Plus className="w-4 h-4 mr-2" />
              Add Header
            </Button>
          </div>
        )}
      </div>

      <div className="border rounded-lg">
        <button
          type="button"
          onClick={() => toggleSection('body')}
          className="w-full flex items-center justify-between p-3 hover:bg-gray-50"
        >
          <span className="font-medium text-gray-900">Request Body (JSON)</span>
          {expandedSections.body ? (
            <ChevronUp className="w-4 h-4 text-gray-500" />
          ) : (
            <ChevronDown className="w-4 h-4 text-gray-500" />
          )}
        </button>
        {expandedSections.body && (
          <div className="p-3 border-t space-y-2">
            {triggerSchema.length > 0 && (
              <div className="bg-blue-50 border border-blue-200 rounded p-2 mb-3">
                <p className="text-xs font-medium text-blue-900 mb-2">
                  Available Trigger Fields (click to insert):
                </p>
                <div className="flex flex-wrap gap-1">
                  {triggerSchema.map((field: any) => (
                    <button
                      key={field.field}
                      type="button"
                      onClick={() => {
                        if (config.body.length === 0) {
                          addKeyValuePair('body')
                        }
                      }}
                      className="text-xs px-2 py-1 bg-blue-100 text-blue-800 rounded hover:bg-blue-200 font-mono"
                      title={field.description}
                    >
                      {field.field}
                    </button>
                  ))}
                </div>
              </div>
            )}
            {config.body.length === 0 ? (
              <p className="text-sm text-gray-500 text-center py-2">No body parameters added</p>
            ) : (
              config.body.map((param, index) => (
                <div key={index} className="space-y-2 p-3 bg-gray-50 rounded">
                  <div className="flex items-start space-x-2">
                    <Input
                      type="text"
                      value={param.key}
                      onChange={(e) => updateKeyValuePair('body', index, e.target.value, param.value)}
                      placeholder="Field Name"
                      className="flex-1 bg-white"
                    />
                    <Button
                      type="button"
                      size="sm"
                      variant="ghost"
                      onClick={() => removeKeyValuePair('body', index)}
                      className="text-red-600 hover:text-red-700"
                    >
                      <X className="w-4 h-4" />
                    </Button>
                  </div>
                  <div className="space-y-1">
                    <Input
                      type="text"
                      value={param.value}
                      onChange={(e) => updateKeyValuePair('body', index, param.key, e.target.value)}
                      placeholder="Value or {{trigger_field}}"
                      className="bg-white"
                    />
                    {triggerSchema.length > 0 && (
                      <div className="flex flex-wrap gap-1">
                        {triggerSchema.map((field: any) => (
                          <button
                            key={field.field}
                            type="button"
                            onClick={() => insertTriggerField('body', index, field.field)}
                            className="text-xs px-2 py-0.5 bg-blue-100 text-blue-700 rounded hover:bg-blue-200 font-mono"
                            title={`Insert ${field.field}`}
                          >
                            {field.field}
                          </button>
                        ))}
                      </div>
                    )}
                  </div>
                </div>
              ))
            )}
            <Button
              type="button"
              size="sm"
              variant="outline"
              onClick={() => addKeyValuePair('body')}
              className="w-full"
            >
              <Plus className="w-4 h-4 mr-2" />
              Add Body Parameter
            </Button>
          </div>
        )}
      </div>

      <div className="bg-gray-50 border border-gray-200 rounded p-3">
        <p className="text-xs text-gray-700 mb-1">
          <strong>Tip:</strong> Use trigger field placeholders in values
        </p>
        <p className="text-xs text-gray-600 font-mono">
          Example: {"{{name}}"}, {"{{email}}"}, {"{{phone}}"}
        </p>
      </div>
    </div>
  )
}
