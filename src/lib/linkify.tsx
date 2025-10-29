import React from 'react'

export function linkify(text: string): React.ReactNode[] {
  if (!text) return []

  const urlRegex = /(https?:\/\/[^\s]+)/g
  const parts = text.split(urlRegex)

  return parts.map((part, index) => {
    if (part.match(urlRegex)) {
      return (
        <a
          key={index}
          href={part}
          target="_blank"
          rel="noopener noreferrer"
          className="text-blue-600 hover:text-blue-800 underline"
        >
          {part}
        </a>
      )
    }
    return <span key={index}>{part}</span>
  })
}

export function linkifyText(text: string): React.ReactNode {
  if (!text) return null

  const lines = text.split('\n')

  return (
    <>
      {lines.map((line, lineIndex) => (
        <React.Fragment key={lineIndex}>
          {linkify(line)}
          {lineIndex < lines.length - 1 && <br />}
        </React.Fragment>
      ))}
    </>
  )
}
