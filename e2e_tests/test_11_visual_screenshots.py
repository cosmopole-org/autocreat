"""Visual screenshot tests: capture full-page screenshots of all major sections."""
import time
import pytest
import requests
from conftest import (
    APP_URL, wait_for_flutter, screenshot, get_all_visible_text,
    login_as_demo, navigate_to, get_driver
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


class TestVisualScreenshots:
    """Capture full-page screenshots of all major UI sections for visual inspection."""

    def test_screenshot_login_page(self, fresh_driver):
        """Capture login page at 1440px."""
        fresh_driver.set_window_size(1440, 900)
        fresh_driver.get(f"{APP_URL}/#/login")
        wait_for_flutter(fresh_driver)
        time.sleep(2)
        path = screenshot(fresh_driver, "11_visual_01_login")
        texts = get_all_visible_text(fresh_driver)
        assert "sign in" in " ".join(texts).lower(), f"Login page blank: {path}"

    def test_screenshot_register_page(self, fresh_driver):
        """Capture register page."""
        fresh_driver.set_window_size(1440, 900)
        fresh_driver.get(f"{APP_URL}/#/register")
        wait_for_flutter(fresh_driver)
        time.sleep(2)
        path = screenshot(fresh_driver, "11_visual_02_register")
        texts = get_all_visible_text(fresh_driver)
        assert len(texts) > 0, f"Register page blank: {path}"

    def test_screenshot_dashboard(self, fresh_driver):
        """Capture dashboard with KPI cards and charts."""
        fresh_driver.set_window_size(1440, 900)
        login_as_demo(fresh_driver)
        navigate_to(fresh_driver, "/dashboard")
        time.sleep(3)
        path = screenshot(fresh_driver, "11_visual_03_dashboard")
        texts = get_all_visible_text(fresh_driver)
        assert len(texts) > 3, f"Dashboard blank: {path}"

    def test_screenshot_flows_list(self, fresh_driver):
        """Capture flows list with statistics."""
        fresh_driver.set_window_size(1440, 900)
        login_as_demo(fresh_driver)
        navigate_to(fresh_driver, "/flows")
        time.sleep(2)
        path = screenshot(fresh_driver, "11_visual_04_flows_list")
        texts = get_all_visible_text(fresh_driver)
        assert "flow" in " ".join(texts).lower(), f"Flows blank: {path}"

    def test_screenshot_flow_editor(self, fresh_driver):
        """Capture flow editor with graph canvas."""
        fresh_driver.set_window_size(1440, 900)
        login_as_demo(fresh_driver)
        token, company_id = get_auth()
        r = requests.get(
            f"{API_BASE}/flows?companyId={company_id}",
            headers={"Authorization": f"Bearer {token}"},
            proxies=PROXIES, timeout=10
        )
        flows = r.json()
        if not flows:
            pytest.skip("No flows available")
        navigate_to(fresh_driver, f"/flows/{flows[0]['id']}/edit")
        time.sleep(6)
        path = screenshot(fresh_driver, "11_visual_05_flow_editor")
        texts = get_all_visible_text(fresh_driver)
        assert len(texts) > 0, f"Flow editor blank: {path}"

    def test_screenshot_forms_list(self, fresh_driver):
        """Capture forms list."""
        fresh_driver.set_window_size(1440, 900)
        login_as_demo(fresh_driver)
        navigate_to(fresh_driver, "/forms")
        time.sleep(2)
        path = screenshot(fresh_driver, "11_visual_06_forms_list")
        texts = get_all_visible_text(fresh_driver)
        assert "form" in " ".join(texts).lower(), f"Forms blank: {path}"

    def test_screenshot_form_editor(self, fresh_driver):
        """Capture form editor with fields panel."""
        fresh_driver.set_window_size(1440, 900)
        login_as_demo(fresh_driver)
        token, company_id = get_auth()
        r = requests.get(
            f"{API_BASE}/forms?companyId={company_id}",
            headers={"Authorization": f"Bearer {token}"},
            proxies=PROXIES, timeout=10
        )
        forms = r.json()
        if not forms:
            pytest.skip("No forms available")
        navigate_to(fresh_driver, f"/forms/{forms[0]['id']}/edit")
        time.sleep(5)
        path = screenshot(fresh_driver, "11_visual_07_form_editor")
        texts = get_all_visible_text(fresh_driver)
        assert len(texts) > 0, f"Form editor blank: {path}"

    def test_screenshot_tickets_list(self, fresh_driver):
        """Capture tickets list."""
        fresh_driver.set_window_size(1440, 900)
        login_as_demo(fresh_driver)
        navigate_to(fresh_driver, "/tickets")
        time.sleep(2)
        path = screenshot(fresh_driver, "11_visual_08_tickets_list")
        texts = get_all_visible_text(fresh_driver)
        assert "ticket" in " ".join(texts).lower(), f"Tickets blank: {path}"

    def test_screenshot_ticket_detail(self, fresh_driver):
        """Capture ticket detail with message thread."""
        fresh_driver.set_window_size(1440, 900)
        login_as_demo(fresh_driver)
        token, company_id = get_auth()
        r = requests.get(
            f"{API_BASE}/tickets?companyId={company_id}",
            headers={"Authorization": f"Bearer {token}"},
            proxies=PROXIES, timeout=10
        )
        tickets = r.json()
        if not tickets:
            pytest.skip("No tickets available")
        navigate_to(fresh_driver, f"/tickets/{tickets[0]['id']}")
        time.sleep(4)
        path = screenshot(fresh_driver, "11_visual_09_ticket_detail")
        texts = get_all_visible_text(fresh_driver)
        assert len(texts) > 0, f"Ticket detail blank: {path}"

    def test_screenshot_users_list(self, fresh_driver):
        """Capture users list."""
        fresh_driver.set_window_size(1440, 900)
        login_as_demo(fresh_driver)
        navigate_to(fresh_driver, "/users")
        time.sleep(2)
        path = screenshot(fresh_driver, "11_visual_10_users_list")
        texts = get_all_visible_text(fresh_driver)
        assert len(texts) > 0, f"Users blank: {path}"

    def test_screenshot_roles_list(self, fresh_driver):
        """Capture roles list."""
        fresh_driver.set_window_size(1440, 900)
        login_as_demo(fresh_driver)
        navigate_to(fresh_driver, "/roles")
        time.sleep(2)
        path = screenshot(fresh_driver, "11_visual_11_roles_list")
        texts = get_all_visible_text(fresh_driver)
        assert len(texts) > 0, f"Roles blank: {path}"

    def test_screenshot_role_editor(self, fresh_driver):
        """Capture role editor with permission matrix."""
        fresh_driver.set_window_size(1440, 900)
        login_as_demo(fresh_driver)
        token, company_id = get_auth()
        r = requests.get(
            f"{API_BASE}/roles?companyId={company_id}",
            headers={"Authorization": f"Bearer {token}"},
            proxies=PROXIES, timeout=10
        )
        roles = r.json()
        if not roles:
            pytest.skip("No roles available")
        navigate_to(fresh_driver, f"/roles/{roles[0]['id']}/edit")
        time.sleep(5)
        path = screenshot(fresh_driver, "11_visual_12_role_editor")
        texts = get_all_visible_text(fresh_driver)
        assert len(texts) > 0, f"Role editor blank: {path}"

    def test_screenshot_letters_list(self, fresh_driver):
        """Capture letters list."""
        fresh_driver.set_window_size(1440, 900)
        login_as_demo(fresh_driver)
        navigate_to(fresh_driver, "/letters")
        time.sleep(2)
        path = screenshot(fresh_driver, "11_visual_13_letters_list")
        texts = get_all_visible_text(fresh_driver)
        assert len(texts) > 0, f"Letters blank: {path}"

    def test_screenshot_letter_editor(self, fresh_driver):
        """Capture letter editor."""
        fresh_driver.set_window_size(1440, 900)
        login_as_demo(fresh_driver)
        token, company_id = get_auth()
        r = requests.get(
            f"{API_BASE}/letters?companyId={company_id}",
            headers={"Authorization": f"Bearer {token}"},
            proxies=PROXIES, timeout=10
        )
        letters = r.json()
        if not letters:
            pytest.skip("No letters available")
        navigate_to(fresh_driver, f"/letters/{letters[0]['id']}/edit")
        time.sleep(6)
        path = screenshot(fresh_driver, "11_visual_14_letter_editor")
        texts = get_all_visible_text(fresh_driver)
        assert len(texts) > 0, f"Letter editor blank: {path}"

    def test_screenshot_models_list(self, fresh_driver):
        """Capture models list."""
        fresh_driver.set_window_size(1440, 900)
        login_as_demo(fresh_driver)
        navigate_to(fresh_driver, "/models")
        time.sleep(2)
        path = screenshot(fresh_driver, "11_visual_15_models_list")
        texts = get_all_visible_text(fresh_driver)
        assert len(texts) > 0, f"Models blank: {path}"

    def test_screenshot_settings_page(self, fresh_driver):
        """Capture settings with all options."""
        fresh_driver.set_window_size(1440, 900)
        login_as_demo(fresh_driver)
        navigate_to(fresh_driver, "/settings")
        time.sleep(2)
        path = screenshot(fresh_driver, "11_visual_16_settings")
        texts = get_all_visible_text(fresh_driver)
        assert "setting" in " ".join(texts).lower(), f"Settings blank: {path}"

    def test_screenshot_companies_page(self, fresh_driver):
        """Capture companies page."""
        fresh_driver.set_window_size(1440, 900)
        login_as_demo(fresh_driver)
        navigate_to(fresh_driver, "/companies")
        time.sleep(2)
        path = screenshot(fresh_driver, "11_visual_17_companies")
        texts = get_all_visible_text(fresh_driver)
        assert len(texts) > 0, f"Companies blank: {path}"

    def test_screenshot_mobile_dashboard(self, fresh_driver):
        """Capture dashboard in mobile layout."""
        fresh_driver.set_window_size(390, 844)
        login_as_demo(fresh_driver)
        navigate_to(fresh_driver, "/dashboard")
        time.sleep(3)
        path = screenshot(fresh_driver, "11_visual_18_mobile_dashboard")
        texts = get_all_visible_text(fresh_driver)
        assert len(texts) > 0, f"Mobile dashboard blank: {path}"

    def test_screenshot_dark_mode_dashboard(self, fresh_driver):
        """Capture dashboard in dark mode."""
        fresh_driver.set_window_size(1440, 900)
        login_as_demo(fresh_driver)
        navigate_to(fresh_driver, "/settings")
        time.sleep(2)
        from conftest import click_button_by_text
        click_button_by_text(fresh_driver, "Dark")
        time.sleep(1)
        navigate_to(fresh_driver, "/dashboard")
        time.sleep(2)
        path = screenshot(fresh_driver, "11_visual_19_dark_dashboard")
        texts = get_all_visible_text(fresh_driver)
        assert len(texts) > 0, f"Dark dashboard blank: {path}"
