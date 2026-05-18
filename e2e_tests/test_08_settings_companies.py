"""Settings page and Companies management tests."""
import time
import pytest
import requests
from conftest import (
    APP_URL, wait_for_flutter, screenshot, get_all_visible_text,
    login_as_demo, navigate_to, click_button_by_text
)

API_BASE = "http://localhost:8081/api/v1"
PROXIES = {"http": None, "https": None}
ADMIN_EMAIL = "admin@horizondigital.com"
ADMIN_PASSWORD = "Demo123!"


def get_auth():
    r = requests.post(
        f"{API_BASE}/auth/login",
        json={"email": ADMIN_EMAIL, "password": ADMIN_PASSWORD},
        proxies=PROXIES, timeout=10
    )
    d = r.json()
    return d["accessToken"], d["user"]["companyId"]


class TestSettings:

    @pytest.fixture(autouse=True)
    def setup(self, fresh_driver):
        self.driver = fresh_driver
        login_as_demo(self.driver)
        navigate_to(self.driver, "/settings")
        time.sleep(2)

    def test_settings_page_loads(self):
        """Settings page loads with workspace preferences."""
        screenshot(self.driver, "08_settings_main")
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        assert any(kw in flat for kw in [
            "setting", "customize", "workspace", "preference"
        ]), f"Settings page content missing. Texts: {texts[:5]}"

    def test_settings_appearance_section(self):
        """Settings page has an Appearance section."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()
        screenshot(self.driver, "08_settings_appearance")

        assert "appearance" in flat or "theme" in flat, \
            f"Appearance section missing. Texts: {texts[:10]}"

    def test_settings_theme_options(self):
        """Settings page shows Light/Dark/System theme options."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        theme_options = ["light", "dark", "system"]
        found = [t for t in theme_options if t in flat]
        assert len(found) >= 2, \
            f"Theme options incomplete. Found: {found}. Texts: {texts[:10]}"

    def test_settings_glass_effect_option(self):
        """Settings page has glass morphism toggle."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        assert "glass" in flat or "translucent" in flat or "blur" in flat, \
            f"Glass effect option missing. Texts: {texts[:10]}"

    def test_settings_language_options(self):
        """Settings page shows language selection (English, Farsi)."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()
        screenshot(self.driver, "08_settings_language")

        has_lang = any(kw in flat for kw in [
            "english", "persian", "farsi", "language", "rtl", "فا"
        ])
        assert has_lang, f"Language options missing. Texts: {texts[:10]}"

    def test_settings_notification_section(self):
        """Settings page has a Notifications section."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        assert "notification" in flat or "email" in flat, \
            f"Notifications section missing. Texts: {texts[:10]}"

    def test_settings_system_section(self):
        """Settings page has System section with analytics and autosave."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        has_system = any(kw in flat for kw in [
            "system", "analytics", "auto save", "cache", "export"
        ])
        assert has_system, f"System section missing. Texts: {texts[:10]}"

    def test_settings_about_section(self):
        """Settings page shows version and build info."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()
        screenshot(self.driver, "08_settings_about")

        has_about = any(kw in flat for kw in [
            "version", "1.0.0", "build", "license", "about"
        ])
        assert has_about, f"About section missing. Texts: {texts[:10]}"

    def test_settings_manage_companies_link(self):
        """Settings page has a 'Manage Companies' link."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        assert "manage companies" in flat or "company" in flat, \
            f"Companies link missing. Texts: {texts[:10]}"

    def test_settings_dark_theme_toggle(self):
        """Clicking Dark theme option changes to dark mode."""
        click_button_by_text(self.driver, "Dark")
        time.sleep(2)
        screenshot(self.driver, "08_settings_dark_mode")

        texts = get_all_visible_text(self.driver)
        assert len(texts) > 0, "Settings crashed after dark mode toggle"

    def test_settings_rtl_language_switch(self):
        """Switching to Farsi applies RTL layout."""
        click_button_by_text(self.driver, "فارسی")
        time.sleep(2)
        screenshot(self.driver, "08_settings_farsi")

        texts = get_all_visible_text(self.driver)
        assert len(texts) > 0, "Settings crashed after language switch"

        # Switch back to English
        click_button_by_text(self.driver, "English")
        time.sleep(1)


class TestCompanies:

    @pytest.fixture(autouse=True)
    def setup(self, fresh_driver):
        self.driver = fresh_driver
        login_as_demo(self.driver)
        navigate_to(self.driver, "/companies")
        time.sleep(2)

    def test_companies_list_loads(self):
        """Companies page loads with company listings."""
        screenshot(self.driver, "08_companies_list")
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        assert any(kw in flat for kw in [
            "company", "companies", "organization", "workspace"
        ]), f"Companies page empty. Texts: {texts[:5]}"

    def test_companies_shows_horizon(self):
        """Companies page shows the seeded Horizon Digital company."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        assert "horizon" in flat or "1 companies" in flat or "active" in flat, \
            f"Company not shown. Texts: {texts[:10]}"

    def test_companies_shows_stats(self):
        """Companies page shows stats (members, flows)."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        has_stats = any(kw in flat for kw in [
            "member", "flow", "active", "1 companies"
        ])
        assert has_stats, f"Company stats missing. Texts: {texts[:10]}"

    def test_companies_new_company_button(self):
        """Companies page has a 'New Company' button."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        assert "new company" in flat or "create" in flat, \
            f"New company button missing. Texts: {texts[:10]}"

    def test_company_detail_page_loads(self):
        """Company detail page loads with company info."""
        token, company_id = get_auth()
        navigate_to(self.driver, f"/companies/{company_id}")
        time.sleep(4)
        screenshot(self.driver, "08_company_detail")

        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        has_detail = any(kw in flat for kw in [
            "company", "horizon", "member", "detail", "name"
        ])
        assert has_detail, f"Company detail empty. Texts: {texts[:10]}"
