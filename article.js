const params = new URLSearchParams(location.search);
const slug = params.get("slug");

document.addEventListener("DOMContentLoaded", async () => {
  document.querySelector("#year").textContent = new Date().getFullYear();
  initTheme();
  if (!slug) return showError("Không tìm thấy bài viết.");
  await loadArticle();
});

async function loadArticle() {
  try {
    const { data: post, error } = await sb
      .from("posts")
      .select("*")
      .eq("slug", slug)
      .eq("published", true)
      .single();

    if (error || !post) throw error || new Error("Not found");

    document.title = `${post.title} - RUBU SCRIPT`;
    const article = document.querySelector("#article");

    article.innerHTML = `
      ${post.image_url ? `<img class="article-image" src="${esc(post.image_url)}" alt="${esc(post.title)}">` : ""}
      <div class="article-body">
        <span class="badge">${esc(post.category || "Roblox")}</span>
        <h1>${esc(post.title)}</h1>
        <div class="article-meta">◉ ${Number(post.views || 0).toLocaleString("vi-VN")} lượt xem · ${new Date(post.created_at).toLocaleDateString("vi-VN")}</div>
        ${post.description ? `<p class="lead">${esc(post.description)}</p>` : ""}
        ${post.content ? `<div class="prose">${formatText(post.content)}</div>` : ""}
        ${post.code ? `
          <div class="code-head"><span>Script / Code</span><button id="copyBtn" class="small-btn">Copy Script</button></div>
          <pre id="codeBox"><code>${esc(post.code)}</code></pre>
        ` : ""}
        ${post.external_link ? `<a class="primary-btn inline-btn" href="${esc(post.external_link)}" target="_blank" rel="noopener noreferrer">Mở liên kết →</a>` : ""}
      </div>`;

    document.querySelector("#copyBtn")?.addEventListener("click", async () => {
      try {
        await navigator.clipboard.writeText(post.code);
        document.querySelector("#copyBtn").textContent = "Đã copy ✓";
      } catch {
        alert("Không thể copy tự động. Hãy chọn và copy nội dung.");
      }
    });

    // RPC an toàn: không cho client tự tăng views tùy ý.
    await sb.rpc("increment_post_view", { p_post_id: post.id });
  } catch (e) {
    console.error(e);
    showError("Không tìm thấy bài viết hoặc bài viết chưa được công khai.");
  }
}

function showError(msg) {
  document.querySelector("#article").innerHTML = `<div class="status">${esc(msg)}</div>`;
}
function formatText(text) {
  return esc(text).split(/\n{2,}/).map(p => `<p>${p.replace(/\n/g, "<br>")}</p>`).join("");
}
function esc(v) {
  return String(v ?? "").replace(/[&<>"']/g, c => ({
    "&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#039;"
  }[c]));
}
function initTheme() {
  const saved = localStorage.getItem("rubu-theme");
  if (saved === "light") document.body.classList.add("light");
  document.querySelector("#themeBtn")?.addEventListener("click", () => {
    document.body.classList.toggle("light");
    localStorage.setItem("rubu-theme", document.body.classList.contains("light") ? "light" : "dark");
  });
}
