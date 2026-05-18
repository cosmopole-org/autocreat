"""Form builder tests: list, statistics, editor."""
import time
import pytest
import requests
from conftest import (
    APP_URL, wait_for_flutter, screenshot, get_all_visible_text,
    login_as_demo, navigate_to
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


class TestForms:

    @pytest.fixture(autouse=True)
    def setup(self, fresh_driver):
        self.driver = fresh_driver
        login_as_demo(self.driver)
        navigate_to(self.driver, "/forms")
        time.sleep(2)

    def test_forms_list_loads(self):
        """Forms list page loads with content."""
        screenshot(self.driver, "04_forms_list")
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        assert any(kw in flat for kw in [
            "form", "definition", "field", "build", "structured"
        ]), f"Forms page empty. Texts: {texts[:5]}"

    def test_forms_shows_stats(self):
        """Forms page shows statistics (total forms, fields, etc.)."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        has_stats = any(kw in flat for kw in [
            "total forms", "4 total", "active", "draft", "field"
        ])
        assert has_stats, f"Form stats missing. Texts: {texts[:10]}"

    def test_forms_shows_field_type_distribution(self):
        """Forms page shows field type distribution chart."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        field_types = ["text", "dropdown", "date", "number", "file", "area"]
        found = [ft for ft in field_types if ft in flat]
        assert len(found) >= 2, f"Field types missing. Found: {found}"

    def test_forms_create_button(self):
        """Forms page has a 'New Form' create button."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        assert "new form" in flat or "create" in flat, \
            f"New form button missing. Texts: {texts[:10]}"

    def test_forms_shows_seed_forms(self):
        """Forms list shows seeded demo forms."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        seed_forms = ["onboarding", "feedback", "bug", "project", "report"]
        found = [f for f in seed_forms if f in flat]
        assert len(found) >= 1, \
            f"Seed forms missing. Checked: {seed_forms}. Texts: {texts[:10]}"

    def test_form_editor_opens(self):
        """Form editor page opens with a form's details."""
        token, company_id = get_auth()
        r = requests.get(
            f"{API_BASE}/forms?companyId={company_id}",
            headers={"Authorization": f"Bearer {token}"},
            proxies=PROXIES, timeout=10
        )
        forms = r.json()
        if not forms:
            pytest.skip("No forms in DB")

        form_id = forms[0]["id"]
        navigate_to(self.driver, f"/forms/{form_id}/edit")
        time.sleep(5)
        screenshot(self.driver, "04_form_editor")

        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        has_editor = any(kw in flat for kw in [
            "form", "field", "save", "edit", "name", "label", "type"
        ])
        assert has_editor, f"Form editor empty. Texts: {texts[:10]}"

    def test_forms_active_count(self):
        """Forms list shows active form count."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()
        assert "active" in flat, f"Active count missing. Texts: {texts[:10]}"
