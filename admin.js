let editingPost = null;
let posts = [];
let imageToUpload = null;
const $ = s => document.querySelector(s);

document.addEventListener("DOMContentLoaded", async () => {
  $("#loginForm").addEventListener("submit", login);
  $("#logoutBtn").addEventListener("click", logout);
  $("#newPostBtn").addEventListener("click", () => openEditor());
  $("#closeModal").addEventListener("click", closeEditor);
  $("#cancelBtn").addEventListener("click", closeEditor);
  $("#postForm").addEventListener("submit", savePost);
  $("#postImage").addEventListener("change", previewImage);
  $("#adminSearch").addEventListener("input", renderTable);

  const { data: { session } } = await sb.auth.getSession();
  if (session) await checkAdmin();
  else showLogin();

  sb.auth.onAuthStateChange((_event, session) => {
    if (!session) showLogin();
  });
});

async function login(e) {
  e.preventDefault();
  $("#loginError").textContent = "";
  const { error } = await sb.auth.signInWithPassword({
    email: $("#email").value.trim(),
    password: $("#password").value
  });
  if (error) {
    $("#loginError").textContent = error.message;
    return;
  }
  await checkAdmin();
}

async function checkAdmin() {
  const { data, error } = await sb.rpc("is_admin");
  if (error || !data) {
    await sb.auth.signOut();
    $("#loginError").textContent = "Tài khoản này không có quyền Admin.";
    showLogin();
    return;
  }
  $("#loginPanel").classList.add("hidden");
  $("#dashboard").classList.remove("hidden");
  await loadPosts();
}

async function logout() {
  await sb.auth.signOut();
  showLogin();
}

function showLogin() {
  $("#loginPanel").classList.remove("hidden");
  $("#dashboard").classList.add("hidden");
}

async function loadPosts() {
  const { data, error } = await sb.from("posts")
    .select("*")
    .order("created_at", { ascending: false });
  if (error) return alert(error.message);
  posts = data || [];
  $("#totalPosts").textContent = posts.length.toLocaleString("vi-VN");
  $("#totalViews").textContent = posts.reduce((a,p) => a + Number(p.views || 0), 0).toLocaleString("vi-VN");
  renderTable();
}

function renderTable() {
  const q = ($("#adminSearch").value || "").toLowerCase();
  const items = posts.filter(p => `${p.title} ${p.category}`.toLowerCase().includes(q));
  $("#postsTable").innerHTML = items.map(p => `
    <tr>
      <td><div class="table-title">${esc(p.title)}</div><small>${esc(p.slug)}</small></td>
      <td>${esc(p.category)}</td>
      <td>${Number(p.views || 0).toLocaleString("vi-VN")}</td>
      <td>${p.published ? '<span class="ok">Công khai</span>' : '<span class="muted">Ẩn</span>'}</td>
      <td class="row-actions">
        <button class="small-btn" onclick="editPost('${p.id}')">Sửa</button>
        <button class="small-btn danger" onclick="deletePost('${p.id}')">Xóa</button>
      </td>
    </tr>`).join("");
}

window.editPost = function(id) {
  const p = posts.find(x => x.id === id);
  if (!p) return;
  editingPost = p;
  $("#editorTitle").textContent = "Sửa bài viết";
  $("#postId").value = p.id;
  $("#postTitle").value = p.title || "";
  $("#postCategory").value = p.category || "";
  $("#postSlug").value = p.slug || "";
  $("#postLink").value = p.external_link || "";
  $("#postDescription").value = p.description || "";
  $("#postContent").value = p.content || "";
  $("#postCode").value = p.code || "";
  $("#postFeatured").checked = !!p.featured;
  $("#postPublished").checked = !!p.published;
  $("#imagePreview").innerHTML = p.image_url ? `<img src="${esc(p.image_url)}">` : "";
  imageToUpload = null;
  $("#editorModal").classList.remove("hidden");
};

function openEditor() {
  editingPost = null;
  imageToUpload = null;
  $("#postForm").reset();
  $("#postPublished").checked = true;
  $("#imagePreview").innerHTML = "";
  $("#editorTitle").textContent = "Thêm bài viết";
  $("#editorModal").classList.remove("hidden");
}
function closeEditor() {
  $("#editorModal").classList.add("hidden");
  $("#saveError").textContent = "";
}

function previewImage(e) {
  imageToUpload = e.target.files[0] || null;
  if (!imageToUpload) return;
  if (imageToUpload.size > 5 * 1024 * 1024) {
    $("#saveError").textContent = "Ảnh vượt quá 5MB.";
    e.target.value = "";
    imageToUpload = null;
    return;
  }
  const url = URL.createObjectURL(imageToUpload);
  $("#imagePreview").innerHTML = `<img src="${url}">`;
}

async function savePost(e) {
  e.preventDefault();
  $("#saveError").textContent = "";

  try {
    const title = $("#postTitle").value.trim();
    const category = $("#postCategory").value.trim();
    const slug = ($("#postSlug").value.trim() || slugify(title));
    if (!title || !category) throw new Error("Vui lòng nhập tên bài và danh mục.");

    let image_url = editingPost?.image_url || null;

    if (imageToUpload) {
      const ext = (imageToUpload.name.split(".").pop() || "jpg").toLowerCase();
      const path = `${crypto.randomUUID()}.${ext}`;
      const { error: uploadError } = await sb.storage.from("post-images").upload(path, imageToUpload, {
        cacheControl: "3600",
        upsert: false,
        contentType: imageToUpload.type
      });
      if (uploadError) throw uploadError;
      const { data: publicData } = sb.storage.from("post-images").getPublicUrl(path);
      image_url = publicData.publicUrl;
    }

    const payload = {
      title, category, slug,
      image_url,
      external_link: $("#postLink").value.trim() || null,
      description: $("#postDescription").value.trim() || null,
      content: $("#postContent").value || null,
      code: $("#postCode").value || null,
      featured: $("#postFeatured").checked,
      published: $("#postPublished").checked
    };

    let error;
    if (editingPost) {
      ({ error } = await sb.from("posts").update(payload).eq("id", editingPost.id));
    } else {
      ({ error } = await sb.from("posts").insert(payload));
    }
    if (error) throw error;

    closeEditor();
    await loadPosts();
    alert("Đã lưu bài viết.");
  } catch (err) {
    console.error(err);
    $("#saveError").textContent = err.message || "Có lỗi xảy ra.";
  }
}

window.deletePost = async function(id) {
  const p = posts.find(x => x.id === id);
  if (!p || !confirm(`Xóa bài "${p.title}"?`)) return;
  const { error } = await sb.from("posts").delete().eq("id", id);
  if (error) return alert(error.message);
  await loadPosts();
};

function slugify(s) {
  return s.toLowerCase()
    .normalize("NFD").replace(/[\u0300-\u036f]/g, "")
    .replace(/đ/g, "d").replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "") || `post-${Date.now()}`;
}
function esc(v) {
  return String(v ?? "").replace(/[&<>"']/g, c => ({
    "&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#039;"
  }[c]));
}
