function debounce(fn, wait) {
  let t
  return function (...args) {
    clearTimeout(t)
    t = setTimeout(() => fn.apply(this, args), wait)
  }
}

function createSuggestionItem(text) {
  const li = document.createElement('li')
  li.className = 'px-3 py-2 hover:bg-gray-100 cursor-pointer'
  li.textContent = text
  return li
}

function attachAutocomplete() {
  const input = document.getElementById('comune_nascita')
  if (!input) return
  const suggestions = document.getElementById('comune_suggestions')
  const hidden = document.getElementById('comune_nascita_selected')
  const form = input.closest('form')

  let focusedIndex = -1

  function clearHighlight() {
    focusedIndex = -1
    Array.from(suggestions.children).forEach((c) => c.classList.remove('bg-gray-200'))
  }

  function highlight(index) {
    const children = Array.from(suggestions.children)
    if (children.length === 0) return
    if (index < 0) index = children.length - 1
    if (index >= children.length) index = 0
    clearHighlight()
    focusedIndex = index
    const el = children[focusedIndex]
    el.classList.add('bg-gray-200')
    el.scrollIntoView({ block: 'nearest' })
  }

  const doFetch = debounce(async (value) => {
    if (!value || value.trim().length < 3) {
      suggestions.classList.add('hidden')
      suggestions.innerHTML = ''
      hidden.value = ''
      clearHighlight()
      return
    }

    try {
      const res = await fetch(`/api/comuni?q=${encodeURIComponent(value)}`, { credentials: 'same-origin' })
      if (!res.ok) throw new Error('network')
      const list = await res.json()
      suggestions.innerHTML = ''
      if (!Array.isArray(list) || list.length === 0) {
        suggestions.classList.add('hidden')
        hidden.value = ''
        clearHighlight()
        return
      }

      for (const nome of list) {
        const li = createSuggestionItem(nome)
        li.addEventListener('click', () => {
          input.value = nome
          hidden.value = nome
          suggestions.classList.add('hidden')
          suggestions.innerHTML = ''
          clearHighlight()
          input.focus()
        })
        li.addEventListener('mouseover', () => {
          clearHighlight()
          li.classList.add('bg-gray-200')
          focusedIndex = Array.from(suggestions.children).indexOf(li)
        })
        suggestions.appendChild(li)
      }
      suggestions.classList.remove('hidden')
      // reset keyboard focus index
      focusedIndex = -1
    } catch (err) {
      suggestions.classList.add('hidden')
      suggestions.innerHTML = ''
      hidden.value = ''
      clearHighlight()
    }
  }, 250)

  input.addEventListener('input', (e) => {
    // clear selected when user edits
    hidden.value = ''
    doFetch(e.target.value)
  })

  // keyboard navigation: ArrowDown, ArrowUp, Enter, Escape
  input.addEventListener('keydown', (e) => {
    const children = Array.from(suggestions.children)
    if (e.key === 'ArrowDown') {
      e.preventDefault()
      if (suggestions.classList.contains('hidden')) return
      highlight(focusedIndex + 1)
    } else if (e.key === 'ArrowUp') {
      e.preventDefault()
      if (suggestions.classList.contains('hidden')) return
      highlight(focusedIndex - 1)
    } else if (e.key === 'Enter') {
      if (!suggestions.classList.contains('hidden') && focusedIndex >= 0) {
        e.preventDefault()
        const el = suggestions.children[focusedIndex]
        if (el) el.click()
      }
    } else if (e.key === 'Escape') {
      suggestions.classList.add('hidden')
      clearHighlight()
    }
  })

  // If clicking outside, hide suggestions
  document.addEventListener('click', (e) => {
    if (!suggestions.contains(e.target) && e.target !== input) {
      suggestions.classList.add('hidden')
      clearHighlight()
    }
  })

  // Prevent form submission unless the user selected a listed comune
  if (form) {
    form.addEventListener('submit', (e) => {
      if (!hidden.value || hidden.value !== input.value) {
        e.preventDefault()
        input.focus()
        // simple UI feedback
        input.classList.add('border-red-500')
        setTimeout(() => input.classList.remove('border-red-500'), 1500)
        return false
      }
    })
  }
}

document.addEventListener('DOMContentLoaded', attachAutocomplete)

export default {}
