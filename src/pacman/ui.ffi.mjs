// FFI for updating HTML UI overlay

export function update_ui(score, lives, level, phase) {
  if (typeof window !== 'undefined' && window.updateUI) {
    window.updateUI(score, lives, level, phase);
  }
}
