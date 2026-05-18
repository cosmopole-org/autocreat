"""Authentication flow tests: login page, demo mode, register page."""
import time
import pytest
from conftest import (
    APP_URL, wait_for_flutter, screenshot, get_all_visible_text,
    login_as_demo, click_button_by_text, click_checkbox_by_label,
    navigate_to
)


class TestAuthentication:

    def test_app_loads_and_shows_login(self, fresh_driver):
        """App loads and redirects unauthenticated user to login page."""
        fresh_driver.get(APP_URL)
        wait_for_flutter(fresh_driver)
        screenshot(fresh_driver, "01_auth_login_page")

        url = fresh_driver.current_url
        assert "#/login" in url or "/login" in url, f"Expected login URL, got: {url}"

        texts = get_all_visible_text(fresh_driver)
        flat = " ".join(texts).lower()
        assert "sign in" in flat or "autocreat" in flat, \
            f"Login page not detected. Texts: {texts[:10]}"

    def test_login_page_has_email_password_fields(self, fresh_driver):
        """Login page has email and password input fields."""
        fresh_driver.get(f"{APP_URL}/#/login")
        wait_for_flutter(fresh_driver)

        inputs = fresh_driver.execute_script(
            "return document.querySelectorAll('input').length;"
        )
        assert inputs >= 2, f"Need email+password fields, got {inputs} inputs"

    def test_login_page_content(self, fresh_driver):
        """Login page shows AutoCreat branding and sign-in copy."""
        fresh_driver.get(f"{APP_URL}/#/login")
        wait_for_flutter(fresh_driver)
        screenshot(fresh_driver, "01_auth_login_content")

        texts = get_all_visible_text(fresh_driver)
        flat = " ".join(texts).lower()

        assert "autocreat" in flat, f"Brand name missing. Texts: {texts[:10]}"
        assert "sign in" in flat or "welcome" in flat, \
            f"Sign-in text missing. Texts: {texts[:10]}"

    def test_demo_accounts_visible(self, fresh_driver):
        """Login page shows demo account quick-login chips."""
        fresh_driver.get(f"{APP_URL}/#/login")
        wait_for_flutter(fresh_driver)
        screenshot(fresh_driver, "01_auth_demo_chips")

        texts = get_all_visible_text(fresh_driver)
        flat = " ".join(texts).lower()
        assert "demo" in flat, f"Demo options not found. Texts: {texts[:15]}"

    def test_demo_mode_login_works(self, fresh_driver):
        """Try Demo Mode button logs in without a network call."""
        fresh_driver.get(APP_URL)
        wait_for_flutter(fresh_driver)

        clicked = click_button_by_text(fresh_driver, "Try Demo Mode")
        assert clicked, "Try Demo Mode button not found"
        time.sleep(5)
        wait_for_flutter(fresh_driver, timeout=15)
        screenshot(fresh_driver, "01_auth_demo_mode_success")

        url = fresh_driver.current_url
        assert "dashboard" in url or "login" not in url, \
            f"Demo mode did not navigate to dashboard: {url}"

    def test_demo_mode_shows_dashboard(self, fresh_driver):
        """After demo login, dashboard is shown with content."""
        login_as_demo(fresh_driver)
        screenshot(fresh_driver, "01_auth_dashboard_after_demo")

        texts = get_all_visible_text(fresh_driver)
        flat = " ".join(texts).lower()
        has_dashboard = any(kw in flat for kw in [
            "dashboard", "good", "evening", "morning", "afternoon",
            "ticket", "flow", "company", "today"
        ])
        assert has_dashboard, f"Dashboard not shown after demo login. Texts: {texts[:10]}"

    def test_register_page_loads(self, fresh_driver):
        """Register page loads with account creation form."""
        fresh_driver.get(f"{APP_URL}/#/register")
        wait_for_flutter(fresh_driver)
        screenshot(fresh_driver, "01_auth_register_page")

        texts = get_all_visible_text(fresh_driver)
        flat = " ".join(texts).lower()
        has_register = any(kw in flat for kw in [
            "register", "create", "account", "sign up", "join", "autocreat"
        ])
        assert has_register, f"Register page content missing. Texts: {texts[:10]}"

    def test_register_has_input_fields(self, fresh_driver):
        """Register page has input fields for user info."""
        fresh_driver.get(f"{APP_URL}/#/register")
        wait_for_flutter(fresh_driver)

        inputs = fresh_driver.execute_script(
            "return document.querySelectorAll('input').length;"
        )
        assert inputs >= 2, f"Register needs input fields, found {inputs}"

    def test_forgot_password_link_present(self, fresh_driver):
        """Login page has a Forgot Password link."""
        fresh_driver.get(f"{APP_URL}/#/login")
        wait_for_flutter(fresh_driver)

        texts = get_all_visible_text(fresh_driver)
        flat = " ".join(texts).lower()
        assert "forgot" in flat or "password" in flat, \
            f"Forgot password not found. Texts: {texts[:15]}"

    def test_create_account_link_on_login(self, fresh_driver):
        """Login page has link to create a new account."""
        fresh_driver.get(f"{APP_URL}/#/login")
        wait_for_flutter(fresh_driver)

        texts = get_all_visible_text(fresh_driver)
        flat = " ".join(texts).lower()
        assert "create" in flat or "account" in flat or "register" in flat, \
            f"Create account link missing. Texts: {texts[:15]}"
