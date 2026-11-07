/**
 * Antigravity High-Gloss Lacquer Dynamic Engine (high-gloss-lacquer.js)
 *
 * Implements real-time physical material mechanics:
 * - Dynamic Pointer-Tracked Specular Flare (--mouse-x, --mouse-y)
 * - Automatic stylesheet link injection if missing
 * - MutationObserver for dynamic single-page web app grids
 */

(function () {
  'use strict';

  // Ensure high-gloss-lacquer.css is linked
  function ensureStylesheet() {
    const existing = document.querySelector('link[href*="high-gloss-lacquer.css"]');
    if (!existing) {
      const link = document.createElement('link');
      link.rel = 'stylesheet';
      // Compute relative path based on script location or standard deploy fallback
      const script = document.currentScript;
      if (script && script.src) {
        link.href = script.src.replace(/\.js(\?.*)?$/, '.css$1');
      } else {
        link.href = 'high-gloss-lacquer.css';
      }
      document.head.appendChild(link);
    }
  }

  // Pointer tracker logic
  function bindPointerTracking(element) {
    if (!element || element._lacquerBound) return;
    element._lacquerBound = true;

    function handleMove(clientX, clientY) {
      const rect = element.getBoundingClientRect();
      const x = clientX - rect.left;
      const y = clientY - rect.top;
      element.style.setProperty('--mouse-x', `${x.toFixed(1)}px`);
      element.style.setProperty('--mouse-y', `${y.toFixed(1)}px`);
    }

    element.addEventListener('mousemove', function (e) {
      handleMove(e.clientX, e.clientY);
    });

    element.addEventListener('touchmove', function (e) {
      if (e.touches && e.touches[0]) {
        handleMove(e.touches[0].clientX, e.touches[0].clientY);
      }
    }, { passive: true });
  }

  // Selector list for all tile / card / interactive components
  const TILE_SELECTORS = [
    '.card', '.tile', '.app-card', '.stat-card', '.stat-tile', '.glass-panel',
    '.player-card', '.difficulty-card', '.score-card', '.remediation-card',
    '.hero-readiness-widget', '.dash-metric-card', '.metric-box', '.module-card',
    '.feature-card', '.board-card', '.lesson-card', '.drill-card', '.summary-card',
    '.plan-card', '.pricing-card', '.inventory-card', '.status-card', '.widget-card',
    '.routine-box', '.quick-actions', '[data-gloss="tile"]',
    '[class*="card"]', '[class*="tile"]'
  ].join(',');

  function scanAndBind() {
    try {
      const elements = document.querySelectorAll(TILE_SELECTORS);
      elements.forEach(bindPointerTracking);
    } catch (e) {
      // Fallback
    }
  }

  // Pointer tracking strictly scoped to hovered element to keep entire webpage motionless
  // No global documentElement mousemove listener to eliminate background repaints

  // MutationObserver for dynamic SPAs
  const observer = new MutationObserver(function (mutations) {
    let shouldScan = false;
    for (let i = 0; i < mutations.length; i++) {
      if (mutations[i].addedNodes.length > 0) {
        shouldScan = true;
        break;
      }
    }
    if (shouldScan) {
      scanAndBind();
    }
  });

  // Initialize on DOM ready
  function init() {
    ensureStylesheet();
    scanAndBind();
    if (document.body) {
      observer.observe(document.body, { childList: true, subtree: true });
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();

