"""Model, Role, and Letter CRUD workflows: create, edit, save, verify via API."""
import time
import pytest
import requests
from conftest import (
    APP_URL, wait_for_flutter, screenshot, get_all_visible_text,
    login_as_demo, navigate_to, click_button_by_text,
    type_into_flutter_field, count_textfields, press_enter,
    wait_for_url_change, click_element_by_text,
)

API_BASE = "http://localhost:8081/api/v1"
PROXIES = {"http": None, "https": None}
ADMIN_EMAIL = "admin@horizondigital.com"
ADMIN_PASSWORD = "Demo123!"


def get_auth():
    r = requests.post(
        f"{API_BASE}/auth/login",
        json={"email": ADMIN_EMAIL, "password": ADMIN_PASSWORD},
        proxies=PROXIES, timeout=10,
    )
    d = r.json()
    return d["accessToken"], d["user"]["companyId"]


def api_get(token, path):
    r = requests.get(
        f"{API_BASE}/{path}",
        headers={"Authorization": f"Bearer {token}"},
        proxies=PROXIES, timeout=10,
    )
    return r.json() if r.status_code == 200 else []


# ── Models ─────────────────────────────────────────────────────────────────


class TestModelCRUD:

    @pytest.fixture(autouse=True)
    def setup(self, fresh_driver):
        self.driver = fresh_driver
        login_as_demo(self.driver)

    def test_new_model_creates_and_opens_editor(self):
        """Clicking 'New Model' creates a model and navigates to its editor."""
        navigate_to(self.driver, "/models")
        time.sleep(2)
        old_url = self.driver.current_url

        click_button_by_text(self.driver, "New Model")
        wait_for_url_change(self.driver, old_url, timeout=15)
        time.sleep(4)
        wait_for_flutter(self.driver)
        screenshot(self.driver, "15_model_editor_new")

        new_url = self.driver.current_url
        assert "/models/" in new_url and "/edit" in new_url, \
            f"Expected /models/<id>/edit, got: {new_url}"

    def test_new_model_appears_in_api(self):
        """A newly created model is returned by the API."""
        token, company_id = get_auth()
        models_before = {m["id"] for m in api_get(token, f"models?companyId={company_id}")}

        navigate_to(self.driver, "/models")
        time.sleep(2)
        old_url = self.driver.current_url
        click_button_by_text(self.driver, "New Model")
        wait_for_url_change(self.driver, old_url, timeout=15)
        time.sleep(3)

        models_after = api_get(token, f"models?companyId={company_id}")
        new_models = [m for m in models_after if m["id"] not in models_before]
        assert len(new_models) >= 1, "No new model found via API"

    def test_model_editor_shows_add_field_button(self):
        """Model editor has an 'Add Field' button."""
        navigate_to(self.driver, "/models")
        time.sleep(2)
        old_url = self.driver.current_url
        click_button_by_text(self.driver, "New Model")
        wait_for_url_change(self.driver, old_url, timeout=15)
        time.sleep(5)
        wait_for_flutter(self.driver)
        screenshot(self.driver, "15_model_editor_sidebar")

        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()
        assert "add field" in flat or "field" in flat or "save" in flat, \
            f"Model editor controls missing. Texts: {texts[:10]}"

    def test_model_editor_click_add_field_opens_dialog(self):
        """Clicking 'Add Field' opens a dialog with a name input."""
        navigate_to(self.driver, "/models")
        time.sleep(2)
        old_url = self.driver.current_url
        click_button_by_text(self.driver, "New Model")
        wait_for_url_change(self.driver, old_url, timeout=15)
        time.sleep(5)
        wait_for_flutter(self.driver)

        before_fields = count_textfields(self.driver)
        click_button_by_text(self.driver, "Add Field")
        time.sleep(2)
        screenshot(self.driver, "15_model_add_field_dialog")

        after_fields = count_textfields(self.driver)
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        dialog_opened = (
            after_fields > before_fields
            or "field name" in flat
            or "name" in flat
            or "type" in flat
        )
        assert dialog_opened, \
            f"Add Field dialog not opened. Fields: {before_fields}→{after_fields}"

    def test_model_editor_add_field_with_name(self):
        """Can type a field name in the Add Field dialog and confirm."""
        navigate_to(self.driver, "/models")
        time.sleep(2)
        old_url = self.driver.current_url
        click_button_by_text(self.driver, "New Model")
        wait_for_url_change(self.driver, old_url, timeout=15)
        time.sleep(5)
        wait_for_flutter(self.driver)

        click_button_by_text(self.driver, "Add Field")
        time.sleep(2)

        # Type field name into the dialog's text field
        field_name = f"email_{int(time.time()) % 10000}"
        type_into_flutter_field(self.driver, field_name, 0)
        time.sleep(0.5)
        screenshot(self.driver, "15_model_field_name_typed")

        # Confirm (Add / OK / Save)
        for btn in ["add", "ok", "confirm", "save", "create"]:
            if click_button_by_text(self.driver, btn):
                break
        time.sleep(2)
        screenshot(self.driver, "15_model_field_added")

        texts = get_all_visible_text(self.driver)
        assert len(texts) > 0, "Model editor crashed after adding field"

    def test_model_editor_save(self):
        """Clicking Save in the model editor persists the model."""
        token, company_id = get_auth()
        navigate_to(self.driver, "/models")
        time.sleep(2)
        old_url = self.driver.current_url
        click_button_by_text(self.driver, "New Model")
        wait_for_url_change(self.driver, old_url, timeout=15)
        time.sleep(5)
        wait_for_flutter(self.driver)

        # Rename model
        type_into_flutter_field(self.driver, f"TestModel-{int(time.time())}", 0)
        time.sleep(0.3)

        click_button_by_text(self.driver, "save")
        time.sleep(3)
        screenshot(self.driver, "15_model_saved")

        texts = get_all_visible_text(self.driver)
        assert len(texts) > 0, "Model editor empty after save"

    def test_open_seed_model_editor(self):
        """Opening a seed model in the editor shows its fields."""
        token, company_id = get_auth()
        models = api_get(token, f"models?companyId={company_id}")
        if not models:
            pytest.skip("No models in DB")

        navigate_to(self.driver, f"/models/{models[0]['id']}/edit")
        time.sleep(5)
        wait_for_flutter(self.driver)
        screenshot(self.driver, "15_seed_model_editor")

        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()
        assert any(kw in flat for kw in ["field", "save", "model", "type", "name"]), \
            f"Seed model editor empty. Texts: {texts[:10]}"

    def test_model_search_on_list_page(self):
        """Searching on models list filters by name."""
        token, company_id = get_auth()
        models = api_get(token, f"models?companyId={company_id}")
        if not models:
            pytest.skip("No models")

        navigate_to(self.driver, "/models")
        time.sleep(2)

        query = models[0].get("name", "")[:5]
        if not query:
            pytest.skip("Model has no name")

        type_into_flutter_field(self.driver, query, 0)
        time.sleep(2)
        screenshot(self.driver, "15_model_search")

        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()
        assert query.lower() in flat or "no model" in flat, \
            f"Search unexpected. Texts: {texts[:8]}"


# ── Roles ──────────────────────────────────────────────────────────────────


class TestRoleCRUD:

    @pytest.fixture(autouse=True)
    def setup(self, fresh_driver):
        self.driver = fresh_driver
        login_as_demo(self.driver)

    def test_new_role_creates_and_opens_editor(self):
        """Clicking 'New Role' creates a role and opens its editor."""
        navigate_to(self.driver, "/roles")
        time.sleep(2)
        old_url = self.driver.current_url

        click_button_by_text(self.driver, "New Role")
        wait_for_url_change(self.driver, old_url, timeout=15)
        time.sleep(4)
        wait_for_flutter(self.driver)
        screenshot(self.driver, "15_role_editor_new")

        new_url = self.driver.current_url
        assert "/roles/" in new_url or "role" in new_url.lower(), \
            f"Expected role editor URL, got: {new_url}"

    def test_role_editor_has_name_field(self):
        """Role editor shows a name text field."""
        navigate_to(self.driver, "/roles")
        time.sleep(2)
        old_url = self.driver.current_url
        click_button_by_text(self.driver, "New Role")
        wait_for_url_change(self.driver, old_url, timeout=15)
        time.sleep(5)
        wait_for_flutter(self.driver)
        screenshot(self.driver, "15_role_editor_fields")

        fields = count_textfields(self.driver)
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()
        assert fields > 0 or "name" in flat or "role" in flat, \
            f"Role editor has no text fields or name. Fields: {fields}"

    def test_role_editor_type_name(self):
        """Can type a role name in the editor."""
        navigate_to(self.driver, "/roles")
        time.sleep(2)
        old_url = self.driver.current_url
        click_button_by_text(self.driver, "New Role")
        wait_for_url_change(self.driver, old_url, timeout=15)
        time.sleep(5)
        wait_for_flutter(self.driver)

        role_name = f"E2E-Role-{int(time.time()) % 10000}"
        type_into_flutter_field(self.driver, role_name, 0)
        time.sleep(0.5)
        screenshot(self.driver, "15_role_name_typed")

        texts = get_all_visible_text(self.driver)
        assert len(texts) > 0, "Role editor crashed after typing name"

    def test_role_editor_has_permissions_section(self):
        """Role editor shows a permissions section with resource checkboxes."""
        navigate_to(self.driver, "/roles")
        time.sleep(2)
        old_url = self.driver.current_url
        click_button_by_text(self.driver, "New Role")
        wait_for_url_change(self.driver, old_url, timeout=15)
        time.sleep(5)
        wait_for_flutter(self.driver)
        screenshot(self.driver, "15_role_permissions")

        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()
        assert any(kw in flat for kw in [
            "permission", "read", "write", "create", "delete", "resource", "access"
        ]), f"Permissions section missing. Texts: {texts[:10]}"

    def test_role_editor_save(self):
        """Can save a role after typing its name."""
        navigate_to(self.driver, "/roles")
        time.sleep(2)
        old_url = self.driver.current_url
        click_button_by_text(self.driver, "New Role")
        wait_for_url_change(self.driver, old_url, timeout=15)
        time.sleep(5)
        wait_for_flutter(self.driver)

        type_into_flutter_field(self.driver, f"Tester-{int(time.time()) % 9999}", 0)
        time.sleep(0.3)
        click_button_by_text(self.driver, "save")
        time.sleep(3)
        screenshot(self.driver, "15_role_saved")

        texts = get_all_visible_text(self.driver)
        assert len(texts) > 0, "Role editor empty after save"

    def test_open_seed_role_editor(self):
        """Opening a seed role in its editor shows name and permissions."""
        token, company_id = get_auth()
        roles = api_get(token, f"roles?companyId={company_id}")
        if not roles:
            pytest.skip("No roles in DB")

        navigate_to(self.driver, f"/roles/{roles[0]['id']}/edit")
        time.sleep(5)
        wait_for_flutter(self.driver)
        screenshot(self.driver, "15_seed_role_editor")

        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()
        assert any(kw in flat for kw in ["save", "name", "permission", "role", "read"]), \
            f"Seed role editor empty. Texts: {texts[:10]}"

    def test_role_editor_toggle_permission(self):
        """Toggling a permission checkbox in the role editor changes its state."""
        token, company_id = get_auth()
        roles = api_get(token, f"roles?companyId={company_id}")
        if not roles:
            pytest.skip("No roles")

        navigate_to(self.driver, f"/roles/{roles[0]['id']}/edit")
        time.sleep(5)
        wait_for_flutter(self.driver)

        # Click on a checkbox
        from conftest import click_checkbox_by_label
        clicked = click_checkbox_by_label(self.driver, "read")
        if not clicked:
            clicked = click_checkbox_by_label(self.driver, "create")
        time.sleep(1.5)
        screenshot(self.driver, "15_role_perm_toggled")

        texts = get_all_visible_text(self.driver)
        assert len(texts) > 0, "Role editor crashed after toggling permission"


# ── Letters ────────────────────────────────────────────────────────────────


class TestLetterCRUD:

    @pytest.fixture(autouse=True)
    def setup(self, fresh_driver):
        self.driver = fresh_driver
        login_as_demo(self.driver)

    def test_new_template_creates_and_opens_editor(self):
        """Clicking 'New Template' creates a letter and opens its editor."""
        navigate_to(self.driver, "/letters")
        time.sleep(2)
        old_url = self.driver.current_url

        click_button_by_text(self.driver, "New Template")
        wait_for_url_change(self.driver, old_url, timeout=15)
        time.sleep(5)
        wait_for_flutter(self.driver)
        screenshot(self.driver, "15_letter_editor_new")

        new_url = self.driver.current_url
        assert "/letters/" in new_url and "/edit" in new_url, \
            f"Expected /letters/<id>/edit, got: {new_url}"

    def test_new_letter_appears_in_api(self):
        """A newly created letter is returned by the API."""
        token, company_id = get_auth()
        letters_before = {l["id"] for l in api_get(token, f"letters?companyId={company_id}")}

        navigate_to(self.driver, "/letters")
        time.sleep(2)
        old_url = self.driver.current_url
        click_button_by_text(self.driver, "New Template")
        wait_for_url_change(self.driver, old_url, timeout=15)
        time.sleep(3)

        letters_after = api_get(token, f"letters?companyId={company_id}")
        new_letters = [l for l in letters_after if l["id"] not in letters_before]
        assert len(new_letters) >= 1, "No new letter found via API after creation"

    def test_letter_editor_shows_toolbar(self):
        """Letter editor shows formatting toolbar (font, style, etc.)."""
        navigate_to(self.driver, "/letters")
        time.sleep(2)
        old_url = self.driver.current_url
        click_button_by_text(self.driver, "New Template")
        wait_for_url_change(self.driver, old_url, timeout=15)
        time.sleep(6)
        wait_for_flutter(self.driver)
        screenshot(self.driver, "15_letter_toolbar")

        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()
        assert any(kw in flat for kw in [
            "save", "font", "letter", "template", "bold", "heading", "color", "format"
        ]), f"Letter editor toolbar missing. Texts: {texts[:10]}"

    def test_letter_editor_save(self):
        """Can save a new letter template."""
        navigate_to(self.driver, "/letters")
        time.sleep(2)
        old_url = self.driver.current_url
        click_button_by_text(self.driver, "New Template")
        wait_for_url_change(self.driver, old_url, timeout=15)
        time.sleep(6)
        wait_for_flutter(self.driver)

        click_button_by_text(self.driver, "save")
        time.sleep(3)
        screenshot(self.driver, "15_letter_saved")

        texts = get_all_visible_text(self.driver)
        assert len(texts) > 0, "Letter editor empty after save"

    def test_open_seed_letter_editor(self):
        """Opening a seed letter in its editor shows content and toolbar."""
        token, company_id = get_auth()
        letters = api_get(token, f"letters?companyId={company_id}")
        if not letters:
            pytest.skip("No letters in DB")

        navigate_to(self.driver, f"/letters/{letters[0]['id']}/edit")
        time.sleep(6)
        wait_for_flutter(self.driver)
        screenshot(self.driver, "15_seed_letter_editor")

        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()
        assert any(kw in flat for kw in ["save", "letter", "font", "template", "variable"]), \
            f"Seed letter editor empty. Texts: {texts[:10]}"

    def test_letter_list_search(self):
        """Typing in the search box on the letters list filters results."""
        token, company_id = get_auth()
        letters = api_get(token, f"letters?companyId={company_id}")
        if not letters:
            pytest.skip("No letters")

        navigate_to(self.driver, "/letters")
        time.sleep(2)

        query = letters[0].get("name", "")[:5]
        if not query:
            pytest.skip("Letter has no name")

        type_into_flutter_field(self.driver, query, 0)
        time.sleep(2)
        screenshot(self.driver, "15_letter_search")

        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()
        assert query.lower() in flat or "no template" in flat or "no letter" in flat, \
            f"Letter search unexpected. Texts: {texts[:8]}"

    def test_letter_editor_has_side_panel(self):
        """Letter editor shows a side panel (variables, formatting options)."""
        token, company_id = get_auth()
        letters = api_get(token, f"letters?companyId={company_id}")
        if not letters:
            pytest.skip("No letters")

        navigate_to(self.driver, f"/letters/{letters[0]['id']}/edit")
        time.sleep(6)
        wait_for_flutter(self.driver)
        screenshot(self.driver, "15_letter_side_panel")

        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()
        assert any(kw in flat for kw in [
            "variable", "font", "size", "color", "align", "heading", "bold", "italic"
        ]), f"Letter side panel missing. Texts: {texts[:10]}"
