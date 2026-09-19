document.addEventListener('DOMContentLoaded', () => {
  const menuBtn = document.querySelector('.mobile-menu-btn');
  const navList = document.querySelector('.nav-list');
  const dropdownBtn = document.querySelector('.dropdown-btn');
  const dropdownMenu = document.querySelector('.dropdown-menu');

  // --- Mobile Hamburger Logic ---
  if (menuBtn && navList) {
    menuBtn.addEventListener('click', () => {
      const isOpen = navList.classList.toggle('is-open');
      menuBtn.setAttribute('aria-expanded', isOpen ? 'true' : 'false');
    });
  }
  
  // --- Models Dropdown Click Logic ---
  if (dropdownBtn && dropdownMenu) {
    dropdownBtn.addEventListener('click', (e) => {
      e.stopPropagation(); // Prevents click event from instantly bubbling up to document listener
      const isExpanded = dropdownMenu.classList.toggle('show');
      dropdownBtn.setAttribute('aria-expanded', isExpanded ? 'true' : 'false');
    });
  }

  // --- Close Dropdown if Clicking Elsewhere ---
  document.addEventListener('click', (e) => {
    if (dropdownMenu && dropdownMenu.classList.contains('show')) {
      if (!dropdownBtn.contains(e.target) && !dropdownMenu.contains(e.target)) {
        dropdownMenu.classList.remove('show');
        dropdownBtn.setAttribute('aria-expanded', 'false');
      }
    }
  });
  
  // --- Handle Screen Resizes Safely ---
  window.addEventListener('resize', () => {
    if (window.innerWidth > 768) {
      if (navList) navList.classList.remove('is-open');
      if (menuBtn) menuBtn.setAttribute('aria-expanded', 'false');
    }
  });
});
