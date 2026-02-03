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

  const doFetch = debounce(async (value) => {
    if (!value || value.trim().length < 3) {
      suggestions.classList.add('hidden')
      suggestions.innerHTML = ''
      hidden.value = ''
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
        return
      }

      for (const nome of list) {
        const li = createSuggestionItem(nome)
        li.addEventListener('click', () => {
          input.value = nome
          hidden.value = nome
          suggestions.classList.add('hidden')
          suggestions.innerHTML = ''
          input.focus()
        })
        suggestions.appendChild(li)
      }
      suggestions.classList.remove('hidden')
    } catch (err) {
      suggestions.classList.add('hidden')
      suggestions.innerHTML = ''
      hidden.value = ''
    }
  }, 250)

  input.addEventListener('input', (e) => {
    // clear selected when user edits
    hidden.value = ''
    doFetch(e.target.value)
  })

  // If clicking outside, hide suggestions
  document.addEventListener('click', (e) => {
    if (!suggestions.contains(e.target) && e.target !== input) {
      suggestions.classList.add('hidden')
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
