/* ============================================================
   동작 스크립트 — 직접 고칠 필요 없습니다.
   ============================================================ */
(function () {
  "use strict";

  /* ---------- 1. config 내용을 화면에 반영 ---------- */
  function applyConfig() {
    document.querySelectorAll("[data-site]").forEach(function (el) {
      var key = el.getAttribute("data-site");
      if (key === "name")          el.textContent = SITE.name;
      else if (key === "heroTitle")el.textContent = SITE.heroTitle;
      else if (key === "heroSub") {
        el.textContent = SITE.heroSub || "";
        if (!SITE.heroSub) el.style.display = "none";
      }
    });
    document.title = SITE.name || "Nail Portfolio";

    var y = document.getElementById("year");
    if (y) y.textContent = "2026";

    buildContact();
  }

  function buildContact() {
    var box = document.getElementById("contactLinks");
    if (!box) return;
    var c = SITE.contact || {};
    var links = [];
    if (c.instagram) links.push({ label: "Instagram", href: c.instagram });
    if (c.kakao)     links.push({ label: "카카오톡",   href: c.kakao });
    if (c.email)     links.push({ label: "Email",     href: "mailto:" + c.email });
    if (c.phone)     links.push({ label: c.phone,      href: "tel:" + c.phone.replace(/[^0-9]/g, "") });
    if (!links.length) { box.closest(".contact").style.display = "none"; return; }
    box.innerHTML = links.map(function (l) {
      var ext = /^https?:/.test(l.href) ? ' target="_blank" rel="noopener"' : "";
      return '<a href="' + l.href + '"' + ext + ">" + esc(l.label) + "</a>";
    }).join("");
  }

  /* ---------- 2. 사진 데이터 준비 (없으면 샘플) ---------- */
  var demoMode = !Array.isArray(PHOTOS) || PHOTOS.length === 0;
  var photos = demoMode ? makeDemoPhotos() : PHOTOS.slice();

  function makeDemoPhotos() {
    var tones = ["#efe7dd", "#e7ddd2", "#e3d6cb", "#f0e8e1", "#ddd2c6", "#e9ddd0"];
    var hts   = [360, 440, 320, 480, 360, 420];
    var dates = ["2026.06.20", "2026.06.12", "2026.05.30", "2026.05.18", "2026.05.04", "2026.04.22"];
    return tones.map(function (tone, i) {
      return { src: placeholderSVG(tone, hts[i]), name: "", date: dates[i] };
    });
  }

  function placeholderSVG(bg, h) {
    var svg =
      '<svg xmlns="http://www.w3.org/2000/svg" width="600" height="' + h + '">' +
      '<rect width="100%" height="100%" fill="' + bg + '"/>' +
      '<text x="50%" y="50%" fill="#b29f8c" font-family="serif" font-size="26" ' +
      'text-anchor="middle" dominant-baseline="middle" letter-spacing="6">SAMPLE</text></svg>';
    return "data:image/svg+xml;charset=utf-8," + encodeURIComponent(svg);
  }

  // 카메라 기본 파일명(IMG_1234 등)은 작품 제목으로 안 보이게 숨김
  function cleanName(name) {
    if (!name) return "";
    if (/^(img|dsc|dscn|kakaotalk|screenshot|photo|image|pic|_dsc)[\W_]*\d+/i.test(name)) return "";
    if (/^\d{6,}$/.test(name)) return "";
    return name;
  }

  /* ---------- 3. 갤러리 렌더 ---------- */
  var gallery = document.getElementById("gallery");
  var emptyEl = document.getElementById("galleryEmpty");

  if (photos.length === 0) {
    if (emptyEl) emptyEl.hidden = false;
  } else {
    photos.forEach(function (p, idx) {
      var nm = cleanName(p.name);
      var card = document.createElement("figure");
      card.className = "card";
      card.dataset.index = idx;
      card.innerHTML =
        '<img loading="lazy" src="' + p.src + '" alt="' + esc(nm || p.date || "") + '" />' +
        '<figcaption class="card__overlay"><div>' +
          (p.date ? '<span class="card__date">' + esc(p.date) + "</span>" : "") +
          (nm ? '<div class="card__name">' + esc(nm) + "</div>" : "") +
        "</div></figcaption>";
      card.addEventListener("click", function () { openLightbox(idx); });
      gallery.appendChild(card);
    });
    revealOnScroll();
  }

  if (demoMode) showDemoBanner();

  /* ---------- 4. 라이트박스 ---------- */
  var lb = document.getElementById("lightbox");
  var lbImg = document.getElementById("lbImg");
  var lbCap = document.getElementById("lbCaption");
  var current = 0;

  function openLightbox(idx) {
    current = idx; updateLightbox(); lb.hidden = false;
    document.body.style.overflow = "hidden";
  }
  function closeLightbox() { lb.hidden = true; document.body.style.overflow = ""; }
  function updateLightbox() {
    var p = photos[current];
    var nm = cleanName(p.name);
    lbImg.src = p.src; lbImg.alt = nm || "";
    lbCap.textContent = [nm, p.date].filter(Boolean).join("  ·  ");
  }
  function step(dir) {
    current = (current + dir + photos.length) % photos.length;
    updateLightbox();
  }

  document.getElementById("lbClose").addEventListener("click", closeLightbox);
  document.getElementById("lbPrev").addEventListener("click", function () { step(-1); });
  document.getElementById("lbNext").addEventListener("click", function () { step(1); });
  lb.addEventListener("click", function (e) { if (e.target === lb) closeLightbox(); });
  document.addEventListener("keydown", function (e) {
    if (lb.hidden) return;
    if (e.key === "Escape") closeLightbox();
    else if (e.key === "ArrowLeft") step(-1);
    else if (e.key === "ArrowRight") step(1);
  });
  // 모바일 스와이프
  var touchX = null;
  lb.addEventListener("touchstart", function (e) { touchX = e.touches[0].clientX; }, { passive: true });
  lb.addEventListener("touchend", function (e) {
    if (touchX === null) return;
    var dx = e.changedTouches[0].clientX - touchX;
    if (Math.abs(dx) > 50) step(dx < 0 ? 1 : -1);
    touchX = null;
  });

  /* ---------- 5. 스크롤 등장 효과 ---------- */
  function revealOnScroll() {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (en) {
        if (en.isIntersecting) { en.target.classList.add("is-in"); io.unobserve(en.target); }
      });
    }, { threshold: 0.12 });
    document.querySelectorAll(".card").forEach(function (c, i) {
      c.style.transitionDelay = (i % 3) * 0.08 + "s";
      io.observe(c);
    });
    document.querySelectorAll(".reveal").forEach(function (el) { el.classList.add("is-in"); });
  }

  /* ---------- 6. 메뉴/스크롤 ---------- */
  var nav = document.getElementById("nav");
  window.addEventListener("scroll", function () {
    nav.classList.toggle("is-scrolled", window.scrollY > 30);
  });
  var toggle = document.getElementById("navToggle");
  toggle.addEventListener("click", function () { document.body.classList.toggle("menu-open"); });
  document.querySelectorAll(".nav__links a").forEach(function (a) {
    a.addEventListener("click", function () { document.body.classList.remove("menu-open"); });
  });

  /* ---------- 유틸 ---------- */
  function esc(s) {
    return String(s == null ? "" : s)
      .replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }
  function showDemoBanner() {
    var b = document.createElement("div");
    b.className = "demo-banner";
    b.textContent = "샘플 화면입니다 · images 폴더에 사진을 넣고 ‘사진추가하기’를 누르세요";
    document.body.appendChild(b);
    setTimeout(function () { b.style.opacity = "0"; b.style.transition = "opacity .6s"; }, 6000);
  }

  applyConfig();
})();
