const detector = document.getElementById('detector');
const targetDot = document.getElementById('targetDot');
const coordText = document.getElementById('coordText');
const areaText = document.getElementById('areaText');
const worldIcons = document.getElementById('worldIcons');
const sweep = document.getElementById('sweep');

function formatCoord(value) {
    const sign = value >= 0 ? '+' : '-';
    return `${sign}${Math.abs(Math.floor(value)).toString().padStart(4, '0')}`;
}

function setRadar(data) {
    if (typeof data.coordX === 'number' && typeof data.coordY === 'number') {
        coordText.textContent = `${formatCoord(data.coordX)}, ${formatCoord(data.coordY)}`;
    }

    if (data.area) {
        areaText.textContent = data.area;
    }

    if (!data.hasTarget) {
        targetDot.classList.add('hidden');
        sweep.style.opacity = '0.45';
        return;
    }

    targetDot.classList.remove('hidden');
    sweep.style.opacity = '0.16';

    const maxDistance = Math.max(data.maxDistance || 1, 1);
    const distance = Math.max(Math.min(data.distance || maxDistance, maxDistance), 0);
    const strength = Math.max(Math.min(data.strength || 0, 1), 0);
    const angle = (data.angle || 0) * Math.PI / 180;

    // A videóhoz hasonlóan: ha közel vagy, a jel középre húzódik és nagyobb lesz.
    const radarRadius = 35;
    const pointRadius = (distance / maxDistance) * radarRadius;
    const x = 50 + Math.sin(angle) * pointRadius;
    const y = 50 - Math.cos(angle) * pointRadius;
    const size = 9 + (strength * 18);

    targetDot.style.left = `${x}%`;
    targetDot.style.top = `${y}%`;
    targetDot.style.width = `${size}px`;
    targetDot.style.height = `${size}px`;
    targetDot.style.opacity = `${0.62 + strength * 0.35}`;
}

function setWorldIcons(icons) {
    worldIcons.innerHTML = '';

    for (const icon of icons || []) {
        const el = document.createElement('div');
        el.className = 'world-icon';
        el.style.left = `${icon.x}%`;
        el.style.top = `${icon.y}%`;
        el.style.opacity = Math.max(Math.min(icon.alpha || 0.55, 1), 0.18);
        worldIcons.appendChild(el);
    }
}

window.addEventListener('message', (event) => {
    const data = event.data || {};

    if (data.action === 'show') {
        detector.classList.remove('hidden');
        return;
    }

    if (data.action === 'hide') {
        detector.classList.add('hidden');
        targetDot.classList.add('hidden');
        setWorldIcons([]);
        return;
    }

    if (data.action === 'radar') {
        setRadar(data);
        return;
    }

    if (data.action === 'worldIcons') {
        setWorldIcons(data.icons || []);
    }
});
