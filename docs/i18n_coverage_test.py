"""
Fails if an English doc page has no sibling translation file for a
supported locale. Mirrors the flask-visual lang/check_translations.py
key-gap check, but at file granularity (mkdocs-static-i18n convention:
page.md = en, page.<locale>.md = translation).
"""
from pathlib import Path

DOCS_DIR = Path(__file__).parent
LOCALES = ["ru", "zh", "pt", "es", "fr"]
EXCLUDE_DIRS = {"release-notes"}  # not part of the built site


def english_pages() -> list[Path]:
    pages = []
    for md in DOCS_DIR.rglob("*.md"):
        if md.relative_to(DOCS_DIR).parts[0] in EXCLUDE_DIRS:
            continue
        stem_parts = md.stem.split(".")
        if len(stem_parts) > 1 and stem_parts[-1] in LOCALES:
            continue  # already a translation file
        pages.append(md)
    return pages


def missing_translations() -> dict[str, list[str]]:
    gaps: dict[str, list[str]] = {}
    for page in english_pages():
        for locale in LOCALES:
            translated = page.with_name(f"{page.stem}.{locale}{page.suffix}")
            if not translated.exists():
                gaps.setdefault(locale, []).append(str(page.relative_to(DOCS_DIR)))
    return gaps


def test_translation_coverage():
    gaps = missing_translations()
    if gaps:
        report = "\n".join(
            f"  {locale}: {len(files)} missing -> {files}" for locale, files in gaps.items()
        )
        raise AssertionError(f"Missing translations:\n{report}")
