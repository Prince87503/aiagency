import React, { useState } from 'react'
import { Input } from '@/components/ui/input'
import { getPhoneValidationError, getEmailValidationError } from '@/lib/utils'

interface ValidatedInputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  validationType?: 'phone' | 'email' | 'none'
  isRequired?: boolean
  onValidationChange?: (isValid: boolean) => void
}

export function ValidatedInput({
  validationType = 'none',
  isRequired = false,
  onValidationChange,
  className = '',
  onBlur,
  onChange,
  ...props
}: ValidatedInputProps) {
  const [error, setError] = useState<string | null>(null)

  const validateValue = (value: string) => {
    let validationError: string | null = null

    if (validationType === 'phone') {
      validationError = getPhoneValidationError(value)
    } else if (validationType === 'email') {
      validationError = getEmailValidationError(value, isRequired)
    }

    setError(validationError)
    onValidationChange?.(validationError === null)
    return validationError
  }

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    onChange?.(e)
    if (error) {
      validateValue(e.target.value)
    }
  }

  const handleBlur = (e: React.FocusEvent<HTMLInputElement>) => {
    validateValue(e.target.value)
    onBlur?.(e)
  }

  return (
    <div>
      <Input
        {...props}
        onChange={handleChange}
        onBlur={handleBlur}
        className={`${error ? 'border-red-500' : ''} ${className}`}
      />
      {error && (
        <p className="text-red-500 text-sm mt-1">{error}</p>
      )}
    </div>
  )
}
