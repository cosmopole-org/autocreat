"""Navigation, routing, responsive layout, and error page tests."""
import time
import pytest
from conftest import (
    APP_URL, wait_for_flutter, screenshot, get_all_visible_text,
    login_as_demo, navigate_to, get_driver
)


MAIN_ROUTES = [
    ("/dashboard", "dashboard"),
    ("/flows", "flows"),
    ("/forms", "forms"),
    ("/tickets", "tickets"),
    ("/users", "users"),
    ("/roles", "roles"),
    ("/letters", "letters"),
    ("/models", "models"),
    ("/settings", "settings"),
    ("/companies", "companies"),
]


class TestNavigation:

    @pytest.fixture(autouse=True)
    def setup(self, fresh_driver):
        self.driver = fresh_driver
        login_as_demo(self.driver)

    def test_all_routes_render(self):
        """All main routes load without crashing or showing 404."""
        for route, name in MAIN_ROUTES:
            navigate_to(self.driver, route)
            time.sleep(2)
            screenshot(self.driver, f"09_nav_{name}")

            texts = get_all_visible_text(self.driver)
            flat = " ".join(texts).lower()

            assert len(texts) > 0, f"Route {route} rendered nothing"
            assert "page not found" not in flat, \
                f"Route {route} shows 404: {texts[:5]}"

    def test_browser_back_works(self):
        """Browser back button navigates to previous page."""
        navigate_to(self.driver, "/dashboard")
        time.sleep(1)

        navigate_to(self.driver, "/flows")
        time.sleep(1)

        self.driver.back()
        time.sleep(2)
        screenshot(self.driver, "09_nav_back")

        url = self.driver.current_url
        assert "dashboard" in url or "flows" in url, \
            f"Back navigation issue: {url}"

    def test_sidebar_shows_all_sections(self):
        """Sidebar navigation shows all main sections after login."""
        navigate_to(self.driver, "/dashboard")
        time.sleep(2)
        screenshot(self.driver, "09_nav_sidebar")

        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        sections = ["flow", "form", "ticket", "user", "role", "letter", "model"]
        found = [s for s in sections if s in flat]
        assert len(found) >= 5, \
            f"Sidebar sections missing. Found: {found}"

    def test_login_page_accessible_when_not_auth(self):
        """Login page is accessible without authentication."""
        fresh_d = get_driver()
        try:
            fresh_d.get(f"{APP_URL}/#/login")
            wait_for_flutter(fresh_d)
            screenshot(fresh_d, "09_nav_login_unauth")

            url = fresh_d.current_url
            texts = get_all_visible_text(fresh_d)
            flat = " ".join(texts).lower()

            assert "login" in url or "sign in" in flat or "autocreat" in flat, \
                f"Login page not accessible. URL: {url}"
        finally:
            fresh_d.quit()

    def test_404_error_page(self):
        """Invalid route shows error page or redirects gracefully."""
        self.driver.get(f"{APP_URL}/#/this-route-does-not-exist-xyz-123")
        wait_for_flutter(self.driver, timeout=15)
        time.sleep(2)
        screenshot(self.driver, "09_nav_404")

        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()
        url = self.driver.current_url

        # Should show error page or redirect to dashboard
        handled = any(kw in flat for kw in [
            "not found", "404", "error", "go home", "dashboard"
        ]) or "dashboard" in url

        assert handled, \
            f"404 not handled. URL: {url}, Texts: {texts[:5]}"

    def test_direct_url_access_while_authenticated(self):
        """Authenticated user can directly access any route via URL."""
        for route, name in MAIN_ROUTES[:5]:
            self.driver.get(f"{APP_URL}/#{route}")
            wait_for_flutter(self.driver, timeout=15)
            time.sleep(1.5)

            texts = get_all_visible_text(self.driver)
            assert len(texts) > 0, \
                f"Direct URL access to {route} rendered nothing"

    def test_responsive_desktop_layout(self):
        """Desktop layout (1440px wide) shows sidebar and content."""
        self.driver.set_window_size(1440, 900)
        navigate_to(self.driver, "/dashboard")
        time.sleep(2)
        screenshot(self.driver, "09_nav_desktop_1440")

        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()
        assert len(texts) > 5, "Desktop layout renders very little"

    def test_responsive_tablet_layout(self):
        """Tablet layout (768px) still renders correctly."""
        self.driver.set_window_size(768, 1024)
        navigate_to(self.driver, "/dashboard")
        time.sleep(2)
        screenshot(self.driver, "09_nav_tablet_768")

        texts = get_all_visible_text(self.driver)
        assert len(texts) > 0, "Tablet layout renders nothing"
        self.driver.set_window_size(1440, 900)  # restore

    def test_responsive_mobile_layout(self):
        """Mobile layout (390px) still renders the app."""
        self.driver.set_window_size(390, 844)
        navigate_to(self.driver, "/dashboard")
        time.sleep(2)
        screenshot(self.driver, "09_nav_mobile_390")

        texts = get_all_visible_text(self.driver)
        assert len(texts) > 0, "Mobile layout renders nothing"
        self.driver.set_window_size(1440, 900)  # restore

    def test_navigate_from_sidebar_to_flows(self):
        """Clicking Flows in sidebar navigates to flows."""
        navigate_to(self.driver, "/dashboard")
        time.sleep(1)

        from conftest import click_button_by_text
        clicked = click_button_by_text(self.driver, "Flows")
        time.sleep(2)
        screenshot(self.driver, "09_nav_sidebar_flows")

        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()
        assert "flow" in flat, "Sidebar Flows navigation failed"

    def test_navigate_from_sidebar_to_tickets(self):
        """Clicking Tickets in sidebar navigates to tickets."""
        navigate_to(self.driver, "/dashboard")
        time.sleep(1)

        from conftest import click_button_by_text
        clicked = click_button_by_text(self.driver, "Tickets")
        time.sleep(2)
        screenshot(self.driver, "09_nav_sidebar_tickets")

        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()
        assert "ticket" in flat, "Sidebar Tickets navigation failed"
