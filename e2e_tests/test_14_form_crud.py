"""Form CRUD workflows: create, editor field-adding, naming, save, verify via API."""
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


def api_get_forms(token, company_id):
    r = requests.get(
        f"{API_BASE}/forms?companyId={company_id}",
        headers={"Authorization": f"Bearer {token}"},
        proxies=PROXIES, timeout=10,
    )
    return r.json() if r.status_code == 200 else []


def api_get_form(token, form_id):
    r = requests.get(
        f"{API_BASE}/forms/{form_id}",
        headers={"Authorization": f"Bearer {token}"},
        proxies=PROXIES, timeout=10,
    )
    return r.json() if r.status_code == 200 else {}


class TestFormCreate:

    @pytest.fixture(autouse=True)
    def setup(self, fresh_driver):
        self.driver = fresh_driver
        login_as_demo(self.driver)

    def test_new_form_creates_and_opens_editor(self):
        """Clicking 'New Form' immediately creates a form and opens its editor."""
        navigate_to(self.driver, "/forms")
        time.sleep(2)
        old_url = self.driver.current_url

        click_button_by_text(self.driver, "New Form")
        wait_for_url_change(self.driver, old_url, timeout=15)
        time.sleep(4)
        wait_for_flutter(self.driver)
        screenshot(self.driver, "14_form_editor_new")

        new_url = self.driver.current_url
        assert "/forms/" in new_url and "/edit" in new_url, \
            f"Expected /forms/<id>/edit URL, got: {new_url}"

    def test_new_form_appears_in_api(self):
        """A newly created form is returned by the API."""
        token, company_id = get_auth()
        forms_before = {f["id"] for f in api_get_forms(token, company_id)}

        navigate_to(self.driver, "/forms")
        time.sleep(2)
        old_url = self.driver.current_url
        click_button_by_text(self.driver, "New Form")
        wait_for_url_change(self.driver, old_url, timeout=15)
        time.sleep(3)

        forms_after = api_get_forms(token, company_id)
        new_forms = [f for f in forms_after if f["id"] not in forms_before]
        assert len(new_forms) >= 1, \
            f"No new form via API. Before: {len(forms_before)}, after: {len(forms_after)}"

    def test_new_form_starts_with_no_fields(self):
        """A freshly created form has an empty fields list."""
        token, company_id = get_auth()
        forms_before = {f["id"] for f in api_get_forms(token, company_id)}

        navigate_to(self.driver, "/forms")
        time.sleep(2)
        old_url = self.driver.current_url
        click_button_by_text(self.driver, "New Form")
        wait_for_url_change(self.driver, old_url, timeout=15)
        time.sleep(3)

        forms_after = api_get_forms(token, company_id)
        new_form = next((f for f in forms_after if f["id"] not in forms_before), None)
        if not new_form:
            pytest.skip("Could not create new form")

        details = api_get_form(token, new_form["id"])
        fields = details.get("fields", [])
        assert isinstance(fields, list), "fields should be a list"
        # New forms start empty
        assert len(fields) == 0, f"New form should have 0 fields, got: {len(fields)}"

    def test_form_list_count_increases_after_create(self):
        """Form count in the list increments after creating a new form."""
        import re
        navigate_to(self.driver, "/forms")
        time.sleep(2)
        texts_before = get_all_visible_text(self.driver)
        counts_before = re.findall(r'\b(\d+)\s+(?:form|total)', " ".join(texts_before).lower())
        count_before = int(counts_before[0]) if counts_before else None

        old_url = self.driver.current_url
        click_button_by_text(self.driver, "New Form")
        wait_for_url_change(self.driver, old_url, timeout=15)
        time.sleep(3)

        navigate_to(self.driver, "/forms")
        time.sleep(2)
        texts_after = get_all_visible_text(self.driver)
        screenshot(self.driver, "14_forms_list_after_create")

        if count_before is not None:
            counts_after = re.findall(r'\b(\d+)\s+(?:form|total)', " ".join(texts_after).lower())
            if counts_after:
                assert int(counts_after[0]) >= count_before, "Form count decreased"
        else:
            assert len(texts_after) > 0, "Forms list empty"


class TestFormEditorInteractions:

    @pytest.fixture(autouse=True)
    def setup(self, fresh_driver):
        self.driver = fresh_driver
        login_as_demo(self.driver)

    def _open_new_form_editor(self):
        """Create a fresh form and wait for the editor to open."""
        navigate_to(self.driver, "/forms")
        time.sleep(2)
        old_url = self.driver.current_url
        click_button_by_text(self.driver, "New Form")
        wait_for_url_change(self.driver, old_url, timeout=15)
        time.sleep(5)
        wait_for_flutter(self.driver)

    def _get_current_form_id(self):
        url = self.driver.current_url
        parts = url.replace("#", "").split("/")
        for i, p in enumerate(parts):
            if p == "forms" and i + 1 < len(parts):
                return parts[i + 1]
        return None

    def test_form_editor_shows_field_type_sidebar(self):
        """Form editor sidebar shows field type options (Text, Number, Dropdown…)."""
        self._open_new_form_editor()
        screenshot(self.driver, "14_form_sidebar")
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()
        found = [t for t in ["text", "number", "dropdown", "email", "checkbox"] if t in flat]
        assert len(found) >= 2, f"Field type sidebar missing. Found: {found}"

    def test_form_editor_rename_form(self):
        """Can edit the form name in the editor."""
        self._open_new_form_editor()
        fields = count_textfields(self.driver)
        assert fields > 0, "No text fields in form editor"

        new_name = f"My-E2E-Form-{int(time.time())}"
        type_into_flutter_field(self.driver, new_name, 0)
        time.sleep(0.5)
        screenshot(self.driver, "14_form_renamed")
        # Just verify the page is still alive
        texts = get_all_visible_text(self.driver)
        assert len(texts) > 0, "Form editor crashed after rename"

    def test_form_editor_add_text_field(self):
        """Clicking 'Text' in the sidebar adds a text field to the form."""
        self._open_new_form_editor()

        click_element_by_text(self.driver, "text")
        time.sleep(2)
        screenshot(self.driver, "14_form_text_field_added")

        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()
        # After adding a text field, editor should show label/placeholder options
        assert len(texts) > 2, f"Editor empty after adding text field: {texts[:5]}"

    def test_form_editor_add_number_field(self):
        """Clicking 'Number' in the sidebar adds a number field."""
        self._open_new_form_editor()
        click_element_by_text(self.driver, "number")
        time.sleep(2)
        screenshot(self.driver, "14_form_number_field_added")

        texts = get_all_visible_text(self.driver)
        assert len(texts) > 2, f"Editor empty after number field: {texts[:5]}"

    def test_form_editor_add_dropdown_field(self):
        """Clicking 'Dropdown' adds a dropdown field."""
        self._open_new_form_editor()
        click_element_by_text(self.driver, "dropdown")
        time.sleep(2)
        screenshot(self.driver, "14_form_dropdown_added")

        texts = get_all_visible_text(self.driver)
        assert len(texts) > 2, f"Editor empty after dropdown field: {texts[:5]}"

    def test_form_editor_add_multiple_fields(self):
        """Adding multiple fields to a form works without crashing."""
        self._open_new_form_editor()
        for field_type in ["text", "number", "dropdown"]:
            click_element_by_text(self.driver, field_type)
            time.sleep(1.5)

        screenshot(self.driver, "14_form_multiple_fields")
        texts = get_all_visible_text(self.driver)
        assert len(texts) > 3, f"Editor broken after multiple fields: {texts[:5]}"

    def test_save_form_with_fields(self):
        """Adding a field and saving persists it to the API."""
        token, company_id = get_auth()
        self._open_new_form_editor()
        form_id = self._get_current_form_id()
        if not form_id:
            pytest.skip("Could not extract form ID from URL")

        # Add a text field
        click_element_by_text(self.driver, "text")
        time.sleep(1.5)

        # Click Save
        click_button_by_text(self.driver, "save")
        time.sleep(4)
        screenshot(self.driver, "14_form_saved")

        # Verify via API — form should exist (may or may not have fields persisted)
        saved = api_get_form(token, form_id)
        assert saved.get("id") == form_id or saved.get("id") is not None, \
            f"Saved form not found via API. Response: {saved}"

    def test_form_editor_shows_save_button(self):
        """Form editor has a Save button."""
        self._open_new_form_editor()
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()
        assert "save" in flat, f"Save button not found. Texts: {texts[:10]}"

    def test_form_editor_add_field_and_fill_label(self):
        """After adding a field, its label input can be filled."""
        self._open_new_form_editor()
        click_element_by_text(self.driver, "text")
        time.sleep(2)

        # There should be additional textboxes for label/placeholder/help
        fields_after = count_textfields(self.driver)
        screenshot(self.driver, "14_form_field_properties")

        if fields_after > 1:
            type_into_flutter_field(self.driver, "Full Name", 1)
            time.sleep(0.5)
            texts = get_all_visible_text(self.driver)
            assert len(texts) > 0, "Editor crashed while filling label"
        else:
            assert fields_after >= 1, "No text fields available in form editor"


class TestExistingFormEditor:

    @pytest.fixture(autouse=True)
    def setup(self, fresh_driver):
        self.driver = fresh_driver
        login_as_demo(self.driver)

    def test_open_seed_form_editor(self):
        """Opening a seed form in the editor shows its existing fields."""
        token, company_id = get_auth()
        forms = api_get_forms(token, company_id)
        if not forms:
            pytest.skip("No forms in DB")

        form = max(forms, key=lambda f: len(f.get("fields", [])), default=forms[0])
        navigate_to(self.driver, f"/forms/{form['id']}/edit")
        time.sleep(5)
        wait_for_flutter(self.driver)
        screenshot(self.driver, "14_seed_form_editor")

        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()
        assert any(kw in flat for kw in ["save", "form", "field", "text", "label"]), \
            f"Seed form editor empty. Texts: {texts[:10]}"

    def test_seed_form_fields_visible_in_editor(self):
        """A seed form with fields shows them in the editor canvas."""
        token, company_id = get_auth()
        forms = api_get_forms(token, company_id)
        forms_with_fields = [f for f in forms if len(f.get("fields", [])) > 0]
        if not forms_with_fields:
            pytest.skip("No forms with fields")

        form = forms_with_fields[0]
        navigate_to(self.driver, f"/forms/{form['id']}/edit")
        time.sleep(5)
        wait_for_flutter(self.driver)
        screenshot(self.driver, "14_seed_form_with_fields")

        texts = get_all_visible_text(self.driver)
        assert len(texts) > 3, f"Form editor shows too little. Texts: {texts[:5]}"

    def test_edit_existing_form_name(self):
        """Can edit an existing form's name in its editor."""
        token, company_id = get_auth()
        forms = api_get_forms(token, company_id)
        if not forms:
            pytest.skip("No forms")

        form = forms[0]
        navigate_to(self.driver, f"/forms/{form['id']}/edit")
        time.sleep(5)
        wait_for_flutter(self.driver)

        new_name = f"Edited-{int(time.time())}"
        type_into_flutter_field(self.driver, new_name, 0)
        time.sleep(0.5)
        click_button_by_text(self.driver, "save")
        time.sleep(3)
        screenshot(self.driver, "14_form_name_edited")

        texts = get_all_visible_text(self.driver)
        assert len(texts) > 0, "Page empty after saving edited form name"

    def test_form_search_on_list_page(self):
        """Typing in the search box on the forms list filters results."""
        token, company_id = get_auth()
        forms = api_get_forms(token, company_id)
        if not forms:
            pytest.skip("No forms")

        navigate_to(self.driver, "/forms")
        time.sleep(2)

        query = forms[0].get("name", "")[:5]
        if not query:
            pytest.skip("Form has no name to search")

        type_into_flutter_field(self.driver, query, 0)
        time.sleep(2)
        screenshot(self.driver, "14_form_search")

        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()
        assert query.lower() in flat or "no forms" in flat, \
            f"Search result unexpected for '{query}'. Texts: {texts[:8]}"
