---

## layout: page title: "Documentation" permalink: /documentation/

```
$ ls docs/
```

Every guide from the repository's `docs/` folder, rendered here as a page.
Source of truth lives in [`docs/`](https://github.com/olafkfreund/nixos-template/tree/main/docs) — these pages are generated from it on every deploy.

{% assign doc_pages = site.pages | where_exp: "p", "p.url contains '/docs/'" | sort: "title" %}

**{{ doc_pages | size }} documents**

{% for d in doc_pages %}

- \[{{ d.title }}\]({{ d.url | relative_url }})
  {% endfor %}

---

Looking for something specific? Use your browser's find (Ctrl/Cmd-F), or browse the
[full source on GitHub](https://github.com/olafkfreund/nixos-template/tree/main/docs).
