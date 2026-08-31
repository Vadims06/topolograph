"""
File-existence coverage (see i18n_coverage_test.py) doesn't prove a reader
sees translated text — a locale build can succeed while silently rendering
the English fallback under a localized URL, which is exactly what happened
when switching to Russian on the homepage: the URL and theme chrome (search
placeholder, aria-labels) changed, but the article body stayed English
because mkdocs-material only auto-translates its own chrome, not page
content. This builds the site and spot-checks that the homepage's content
region contains actual target-language text.
"""
import re
import subprocess
import sys
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).parent.parent
LOCALES = ["ru", "zh", "pt", "es", "fr"]

# Enough to prove non-English text is present; not a translation-quality check.
NON_ENGLISH_HINTS = {
    "ru": r"[Ѐ-ӿ]",
    "zh": r"[一-鿿]",
    "pt": r"[àáâãçéêíóôõúÀÁÂÃÇÉÊÍÓÔÕÚ]",
    "es": r"[áéíñóúü¿¡ÁÉÍÑÓÚÜ]",
    "fr": r"[àâçéèêëîïôûùüÿœÀÂÇÉÈÊËÎÏÔÛÙÜŸŒ]",
}

ARTICLE_RE = re.compile(
    r'<article class="md-content__inner md-typeset">(.*?)</article>', re.S
)


def _build_site(site_dir: Path) -> None:
    subprocess.run(
        [sys.executable, "-m", "mkdocs", "build", "--strict", "--site-dir", str(site_dir)],
        cwd=REPO_ROOT,
        check=True,
    )


def _article(html_path: Path) -> str:
    match = ARTICLE_RE.search(html_path.read_text(encoding="utf-8"))
    assert match, f"Could not find main content region in {html_path}"
    return match.group(1)


@pytest.fixture(scope="module")
def site_dir(tmp_path_factory):
    site_dir = tmp_path_factory.mktemp("site")
    _build_site(site_dir)
    return site_dir


@pytest.mark.parametrize("locale", LOCALES)
def test_homepage_renders_translated_content(site_dir, locale):
    article = _article(site_dir / locale / "index.html")
    assert re.search(NON_ENGLISH_HINTS[locale], article), (
        f"{locale}/index.html shows no {locale} text in its content region — "
        f"the language switcher is silently falling back to English. "
        f"Add docs/index.{locale}.md."
    )


@pytest.mark.parametrize("locale", LOCALES)
def test_translation_notice_is_present_on_every_localized_page(site_dir, locale):
    pages = list((site_dir / locale).rglob("*.html"))
    assert pages
    missing = [str(page.relative_to(site_dir)) for page in pages
               if "tg-translation-notice" not in page.read_text(encoding="utf-8")]
    assert not missing, f"Missing translation notice: {missing}"
