"""Letter designer and data model tests."""
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


class TestLetters:

    @pytest.fixture(autouse=True)
    def setup(self, fresh_driver):
        self.driver = fresh_driver
        login_as_demo(self.driver)
        navigate_to(self.driver, "/letters")
        time.sleep(2)

    def test_letters_list_loads(self):
        """Letters list page loads with template data."""
        screenshot(self.driver, "07_letters_list")
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        assert any(kw in flat for kw in [
            "letter", "template", "document", "reusable", "branded"
        ]), f"Letters page empty. Texts: {texts[:5]}"

    def test_letters_shows_template_count(self):
        """Letters page shows total template count."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        has_count = any(kw in flat for kw in [
            "3 total", "total templates", "active", "draft", "variable"
        ])
        assert has_count, f"Template count missing. Texts: {texts[:10]}"

    def test_letters_shows_category_distribution(self):
        """Letters page shows category distribution chart."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        has_dist = any(kw in flat for kw in [
            "category", "distribution", "onboarding", "hr", "delivery"
        ])
        assert has_dist, f"Category distribution missing. Texts: {texts[:10]}"

    def test_letters_shows_seed_templates(self):
        """Letters page shows seeded template names."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        seed_letters = ["welcome", "approval", "contract"]
        found = [l for l in seed_letters if l in flat]
        assert len(found) >= 1, \
            f"Seed letters missing. Found: {found}. Texts: {texts[:10]}"

    def test_letters_new_template_button(self):
        """Letters page has a 'New Template' button."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        assert "new template" in flat or "create" in flat, \
            f"New template button missing. Texts: {texts[:10]}"

    def test_letter_editor_opens(self):
        """Letter editor loads for an existing template."""
        token, company_id = get_auth()
        r = requests.get(
            f"{API_BASE}/letters?companyId={company_id}",
            headers={"Authorization": f"Bearer {token}"},
            proxies=PROXIES, timeout=10
        )
        letters = r.json()
        if not letters:
            pytest.skip("No letters in DB")

        letter_id = letters[0]["id"]
        navigate_to(self.driver, f"/letters/{letter_id}/edit")
        time.sleep(6)
        screenshot(self.driver, "07_letter_editor")

        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        has_editor = any(kw in flat for kw in [
            "letter", "template", "save", "edit", "variable", "content", "font"
        ])
        assert has_editor, f"Letter editor empty. Texts: {texts[:10]}"

    def test_letters_variable_count(self):
        """Letters page shows total variable count."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()
        assert "variable" in flat, f"Variable info missing. Texts: {texts[:10]}"


class TestModels:

    @pytest.fixture(autouse=True)
    def setup(self, fresh_driver):
        self.driver = fresh_driver
        login_as_demo(self.driver)
        navigate_to(self.driver, "/models")
        time.sleep(2)

    def test_models_list_loads(self):
        """Models list page loads with schema definitions."""
        screenshot(self.driver, "07_models_list")
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        assert any(kw in flat for kw in [
            "model", "schema", "field", "entity", "data", "define"
        ]), f"Models page empty. Texts: {texts[:5]}"

    def test_models_shows_field_type_distribution(self):
        """Models page shows field type distribution chart."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        has_types = any(kw in flat for kw in [
            "string", "float", "boolean", "date", "reference", "integer", "field type"
        ])
        assert has_types, f"Field types missing. Texts: {texts[:10]}"

    def test_models_shows_stats(self):
        """Models page shows model count and field statistics."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        has_stats = any(kw in flat for kw in [
            "2 total", "total models", "field", "required", "unique"
        ])
        assert has_stats, f"Model stats missing. Texts: {texts[:10]}"

    def test_models_new_model_button(self):
        """Models page has a 'New Model' button."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        assert "new model" in flat or "create" in flat, \
            f"New model button missing. Texts: {texts[:10]}"

    def test_model_editor_opens(self):
        """Model editor loads for an existing schema."""
        token, company_id = get_auth()
        r = requests.get(
            f"{API_BASE}/models?companyId={company_id}",
            headers={"Authorization": f"Bearer {token}"},
            proxies=PROXIES, timeout=10
        )
        models = r.json()
        if not models:
            pytest.skip("No models in DB")

        model_id = models[0]["id"]
        navigate_to(self.driver, f"/models/{model_id}/edit")
        time.sleep(5)
        screenshot(self.driver, "07_model_editor")

        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        has_editor = any(kw in flat for kw in [
            "model", "field", "type", "name", "save", "schema"
        ])
        assert has_editor, f"Model editor empty. Texts: {texts[:10]}"
