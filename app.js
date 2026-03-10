/* ── App.js – Emma's Pommesblog ── */

const STORAGE_KEY = 'pommesblog_spots';

// ── Map setup ──────────────────────────────────────────────────────────────
const map = L.map('map').setView([51.165, 10.451], 6); // centred on Germany

L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
  attribution: '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
  maxZoom: 19,
}).addTo(map);

// ── State ──────────────────────────────────────────────────────────────────
let pendingLatLng = null;
let selectedRating = 0;

// ── DOM refs ───────────────────────────────────────────────────────────────
const overlay       = document.getElementById('modal-overlay');
const form          = document.getElementById('rating-form');
const spotNameInput = document.getElementById('spot-name');
const ratingHidden  = document.getElementById('rating-value');
const stars         = document.querySelectorAll('.star');
const cancelBtn     = document.getElementById('cancel-btn');
const ratingError   = document.getElementById('rating-error');

// ── Star-rating interactions ───────────────────────────────────────────────
function setStars(value) {
  stars.forEach(star => {
    const starVal = parseInt(star.dataset.value, 10);
    star.classList.toggle('selected', starVal <= value);
    star.classList.remove('hovered');
  });
  selectedRating = value;
  ratingHidden.value = value;
  if (value > 0) {
    ratingError.textContent = '';
    ratingError.classList.add('hidden');
  }
}

stars.forEach(star => {
  star.addEventListener('mouseover', () => {
    const hoverVal = parseInt(star.dataset.value, 10);
    stars.forEach(s => {
      s.classList.toggle('hovered', parseInt(s.dataset.value, 10) <= hoverVal);
    });
  });

  star.addEventListener('mouseout', () => {
    stars.forEach(s => s.classList.remove('hovered'));
  });

  star.addEventListener('click', () => {
    setStars(parseInt(star.dataset.value, 10));
  });

  star.addEventListener('keydown', e => {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      setStars(parseInt(star.dataset.value, 10));
    }
  });
});

// ── Open / close modal ─────────────────────────────────────────────────────
function openModal(latlng) {
  pendingLatLng = latlng;
  selectedRating = 0;
  ratingHidden.value = 0;
  spotNameInput.value = '';
  setStars(0);
  overlay.classList.remove('hidden');
  spotNameInput.focus();
}

function closeModal() {
  overlay.classList.add('hidden');
  pendingLatLng = null;
}

cancelBtn.addEventListener('click', closeModal);

overlay.addEventListener('click', e => {
  if (e.target === overlay) closeModal();
});

// ── Map click ──────────────────────────────────────────────────────────────
map.on('click', e => openModal(e.latlng));

// ── Marker / popup helper ──────────────────────────────────────────────────
function starsHtml(rating) {
  return '★'.repeat(rating) + '☆'.repeat(5 - rating);
}

function addMarker(spot) {
  const marker = L.marker([spot.lat, spot.lng]).addTo(map);
  marker.bindPopup(`
    <div class="popup-content">
      <div class="popup-name">${escapeHtml(spot.name)}</div>
      <div class="popup-stars">${starsHtml(spot.rating)}</div>
      <div class="popup-coords">${spot.lat.toFixed(4)}, ${spot.lng.toFixed(4)}</div>
    </div>
  `);
  return marker;
}

function escapeHtml(str) {
  const div = document.createElement('div');
  div.textContent = str;
  return div.innerHTML;
}

// ── Persistence ────────────────────────────────────────────────────────────
function loadSpots() {
  try {
    return JSON.parse(localStorage.getItem(STORAGE_KEY)) || [];
  } catch {
    return [];
  }
}

function saveSpots(spots) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(spots));
}

// ── Form submit ────────────────────────────────────────────────────────────
form.addEventListener('submit', e => {
  e.preventDefault();

  const name   = spotNameInput.value.trim();
  const rating = parseInt(ratingHidden.value, 10);

  if (!name) {
    spotNameInput.focus();
    return;
  }

  if (rating < 1) {
    ratingError.textContent = 'Please select a star rating.';
    ratingError.classList.remove('hidden');
    stars[0].focus();
    return;
  }

  const spot = {
    name,
    rating,
    lat: pendingLatLng.lat,
    lng: pendingLatLng.lng,
  };

  addMarker(spot);

  const spots = loadSpots();
  spots.push(spot);
  saveSpots(spots);

  closeModal();
});

// ── Restore saved spots on load ────────────────────────────────────────────
loadSpots().forEach(addMarker);
