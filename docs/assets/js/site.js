// Search over the page index Hugo writes (layouts/home.json), the mobile nav toggle, and the
// live cluster numbers on the home page. No dependencies.
(() => {
  const input = document.getElementById("search-input");
  const list = document.getElementById("search-results");
  let index = null;
  let active = -1;

  const load = async () => {
    if (index) return index;
    const res = await fetch(input.dataset.index);
    index = (await res.json()).map((p) => ({
      ...p,
      hay: [p.t, p.d, p.c].join(" ").toLowerCase(),
      title: p.t.toLowerCase(),
    }));
    return index;
  };

  const score = (page, terms) => {
    let total = 0;
    for (const term of terms) {
      if (!page.hay.includes(term)) return 0;
      if (page.title === term) total += 100;
      else if (page.title.startsWith(term)) total += 40;
      else if (page.title.includes(term)) total += 20;
      else total += 1;
    }
    return total;
  };

  const render = (hits) => {
    active = -1;
    list.replaceChildren();
    if (!hits.length) {
      const li = document.createElement("li");
      li.className = "r-none";
      li.textContent = "Nothing found.";
      list.append(li);
    }
    for (const page of hits) {
      const li = document.createElement("li");
      const a = document.createElement("a");
      a.href = page.u;
      const title = document.createElement("span");
      title.className = "r-title";
      title.textContent = page.t;
      a.append(title);
      if (page.s) {
        const sec = document.createElement("span");
        sec.className = "r-sec";
        sec.textContent = page.s;
        a.append(sec);
      }
      if (page.d) {
        const desc = document.createElement("span");
        desc.className = "r-desc";
        desc.textContent = page.d;
        a.append(desc);
      }
      li.append(a);
      list.append(li);
    }
    list.hidden = false;
  };

  const search = async () => {
    const terms = input.value.toLowerCase().split(/\s+/).filter(Boolean);
    if (!terms.length) {
      list.hidden = true;
      return;
    }
    const pages = await load();
    const hits = pages
      .map((p) => [score(p, terms), p])
      .filter(([s]) => s > 0)
      .sort((a, b) => b[0] - a[0] || a[1].t.localeCompare(b[1].t))
      .slice(0, 12)
      .map(([, p]) => p);
    render(hits);
  };

  const move = (step) => {
    const links = [...list.querySelectorAll("a")];
    if (!links.length) return;
    active = (active + step + links.length) % links.length;
    links.forEach((a, i) => a.classList.toggle("is-active", i === active));
    links[active].scrollIntoView({ block: "nearest" });
  };

  if (input && list) {
    input.addEventListener("input", search);
    input.addEventListener("focus", search);
    input.addEventListener("keydown", (e) => {
      if (e.key === "ArrowDown") {
        e.preventDefault();
        move(1);
      } else if (e.key === "ArrowUp") {
        e.preventDefault();
        move(-1);
      } else if (e.key === "Enter") {
        const link = list.querySelector("a.is-active") || list.querySelector("a");
        if (link && !list.hidden) location.href = link.href;
      } else if (e.key === "Escape") {
        list.hidden = true;
        input.blur();
      }
    });
    document.addEventListener("click", (e) => {
      if (!e.target.closest(".search")) list.hidden = true;
    });
    document.addEventListener("keydown", (e) => {
      const typing = /^(INPUT|TEXTAREA|SELECT)$/.test(document.activeElement.tagName);
      if (e.key === "/" && !typing) {
        e.preventDefault();
        input.focus();
      }
    });
  }

  const toggle = document.querySelector(".nav-toggle");
  if (toggle) {
    toggle.addEventListener("click", () => {
      const open = document.body.classList.toggle("nav-open");
      toggle.setAttribute("aria-expanded", String(open));
    });
  }

  // Live numbers from kromgo. If the cluster is unreachable the strip disappears; the rest of
  // the site does not depend on it.
  const live = document.querySelector(".live");
  if (live) {
    const cells = [...live.querySelectorAll("[data-kromgo]")];
    Promise.all(
      cells.map(async (cell) => {
        const res = await fetch(cell.dataset.kromgo, { signal: AbortSignal.timeout(4000) });
        const data = await res.json();
        cell.textContent = data.value;
      }),
    ).catch(() => {
      live.hidden = true;
    });
  }
})();
