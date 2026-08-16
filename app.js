const PAGE_SIZE = 12;
let allPosts = [];
let filteredPosts = [];
let visibleCount = PAGE_SIZE;
let selectedCategory = "";

const $ = (s) => document.querySelector(s);

document.addEventListener("DOMContentLoaded", async () => {
  $("#year").textContent = new Date().getFullYear();
  initTheme();
  $("#searchInput").addEventListener("input", applyFilters);
  $("#loadMore").addEventListener("click", () => {
    visibleCount += PAGE_SIZE;
    renderPosts();
  });
  await loadPosts();
});

async function loadPosts() {
  try {
    const { data, error } = await sb
      .from("posts")
      .select("id,title,slug,category,image_url,description,views,featured,published,created_at")
      .eq("published", true)
      .order("featured", { ascending: false })
      .order("created_at", { ascending: false });

    if (error) throw error;
    allPosts = data || [];
    buildCategories();
    applyFilters();
  } catch (e) {
    $("#status").textContent = "Không thể tải bài viết. Hãy kiểm tra cấu hình Supabase.";
    console.error(e);
  }
}

function buildCategories() {
  const categories = [...new Set(allPosts.map(p => p.category).filter(Boolean))];
  const box = $("#categories");
  box.innerHTML = `<button class="chip active" data-category="">Tất cả</button>`;
  categories.forEach(cat => {
    const btn = document.createElement("button");
    btn.className = "chip";
    btn.dataset.category = cat;
    btn.textContent = cat;
    box.appendChild(btn);
  });
  box.querySelectorAll(".chip").forEach(btn => {
    btn.addEventListener("click", () => {
      selectedCategory = btn.dataset.category;
      box.querySelectorAll(".chip").forEach(x => x.classList.remove("active"));
      btn.classList.add("active");
      visibleCount = PAGE_SIZE;
      applyFilters();
    });
  });
}

function applyFilters() {
  const q = ($("#searchInput").value || "").trim().toLowerCase();
  filteredPosts = allPosts.filter(p => {
    const categoryOK = !selectedCategory || p.category === selectedCategory;
    const text = `${p.title} ${p.category} ${p.description || ""}`.toLowerCase();
    return categoryOK && text.includes(q);
  });
  renderPosts();
}

function renderPosts() {
  const grid = $("#postsGrid");
  grid.innerHTML = "";
  const items = filteredPosts.slice(0, visibleCount);
  $("#status").textContent = filteredPosts.length ? "" : "Không tìm thấy bài viết.";
  $("#loadMore").classList.toggle("hidden", visibleCount >= filteredPosts.length || !filteredPosts.length);

  items.forEach(post => {
    const card = document.createElement("a");
    card.className = "post-card";
    card.href = `article.html?slug=${encodeURIComponent(post.slug)}`;

    const image = post.image_url
      ? `<img src="${escapeAttr(post.image_url)}" alt="${escapeAttr(post.title)}" loading="lazy">`
      : `<div class="placeholder">RUBU<br>SCRIPT</div>`;

    card.innerHTML = `
      <div class="thumb">${image}<span class="badge">${escapeHTML(post.category || "Roblox")}</span></div>
      <div class="post-info">
        <h2>${escapeHTML(post.title)}</h2>
        <div class="post-meta">
          <span>ĐỌC THÊM →</span>
          <span>◉ ${Number(post.views || 0).toLocaleString("vi-VN")}</span>
        </div>
      </div>`;
    grid.appendChild(card);
  });
}

function initTheme() {
  const saved = localStorage.getItem("rubu-theme");
  if (saved === "light") document.body.classList.add("light");
  const btn = $("#themeBtn");
  if (btn) btn.addEventListener("click", () => {
    document.body.classList.toggle("light");
    localStorage.setItem("rubu-theme", document.body.classList.contains("light") ? "light" : "dark");
  });
}

function escapeHTML(v) {
  return String(v ?? "").replace(/[&<>"']/g, c => ({
    "&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#039;"
  }[c]));
}
function escapeAttr(v) { return escapeHTML(v); }
