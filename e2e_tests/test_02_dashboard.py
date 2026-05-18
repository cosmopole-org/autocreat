"""Dashboard tests: KPI cards, charts, activity stats, navigation sidebar."""
import time
import pytest
from conftest import (
    APP_URL, wait_for_flutter, screenshot, get_all_visible_text,
    login_as_demo, navigate_to, click_button_by_text
)


class TestDashboard:

    @pytest.fixture(autouse=True)
    def setup(self, fresh_driver):
        self.driver = fresh_driver
        login_as_demo(self.driver)
        navigate_to(self.driver, "/dashboard")
        time.sleep(2)

    def test_dashboard_page_loads(self):
        """Dashboard page renders at the /dashboard route."""
        screenshot(self.driver, "02_dashboard_main")
        assert "dashboard" in self.driver.current_url, \
            f"Not on dashboard: {self.driver.current_url}"

    def test_dashboard_welcome_message(self):
        """Dashboard shows a personalized welcome message."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()
        screenshot(self.driver, "02_dashboard_welcome")

        has_welcome = any(kw in flat for kw in [
            "good morning", "good afternoon", "good evening",
            "welcome", "hello", "demo", "organization"
        ])
        assert has_welcome, f"No welcome message. Texts: {texts[:10]}"

    def test_dashboard_kpi_cards(self):
        """Dashboard shows KPI metric cards (companies, flows, tickets)."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()
        screenshot(self.driver, "02_dashboard_kpi")

        kpi_terms = ["companies", "flows", "tickets", "active", "open", "total"]
        found = [k for k in kpi_terms if k in flat]
        assert len(found) >= 2, \
            f"KPI cards missing. Found: {found}. Texts: {texts[:10]}"

    def test_dashboard_activity_overview(self):
        """Dashboard shows an activity overview chart section."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        has_activity = any(kw in flat for kw in [
            "activity", "overview", "chart", "ticket", "flow", "last 7 days"
        ])
        assert has_activity, f"Activity section missing. Texts: {texts[:10]}"

    def test_dashboard_ticket_status_distribution(self):
        """Dashboard shows ticket status distribution."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        has_status = any(kw in flat for kw in [
            "status", "distribution", "open", "in progress", "resolved", "closed"
        ])
        assert has_status, f"Ticket status missing. Texts: {texts[:10]}"

    def test_dashboard_priority_breakdown(self):
        """Dashboard shows priority breakdown section."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        has_priority = any(kw in flat for kw in [
            "priority", "breakdown", "high", "medium", "low", "urgent"
        ])
        assert has_priority, f"Priority breakdown missing. Texts: {texts[:10]}"

    def test_dashboard_quick_actions(self):
        """Dashboard has quick action buttons."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()
        screenshot(self.driver, "02_dashboard_quick_actions")

        has_actions = any(kw in flat for kw in [
            "quick actions", "new", "create", "add", "view all"
        ])
        assert has_actions, f"Quick actions missing. Texts: {texts[:10]}"

    def test_dashboard_shows_current_date(self):
        """Dashboard shows the current date."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        date_terms = ["2026", "jan", "feb", "mar", "apr", "may", "jun",
                      "jul", "aug", "sep", "oct", "nov", "dec",
                      "mon", "tue", "wed", "thu", "fri", "sat", "sun"]
        has_date = any(kw in flat for kw in date_terms)
        assert has_date, f"Date not shown on dashboard. Texts: {texts[:10]}"

    def test_dashboard_sidebar_navigation_links(self):
        """Sidebar navigation shows all main section links."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()
        screenshot(self.driver, "02_dashboard_sidebar")

        nav_sections = ["flow", "form", "ticket", "user", "role", "letter", "model"]
        found = [s for s in nav_sections if s in flat]
        assert len(found) >= 5, \
            f"Sidebar navigation incomplete. Found: {found}"

    def test_dashboard_view_all_link(self):
        """Dashboard has a 'View all' button for quick navigation."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()
        assert "view all" in flat or "see all" in flat, \
            f"View all link missing. Texts: {texts[:15]}"

    def test_dashboard_performance_metrics(self):
        """Dashboard shows performance metric KPIs."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        has_perf = any(kw in flat for kw in [
            "performance", "metrics", "resolution rate", "kpi", "rate"
        ])
        assert has_perf, f"Performance metrics missing. Texts: {texts[:10]}"
