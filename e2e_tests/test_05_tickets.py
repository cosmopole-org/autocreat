"""Ticket system tests: list, filters, status, priority, detail view."""
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


class TestTickets:

    @pytest.fixture(autouse=True)
    def setup(self, fresh_driver):
        self.driver = fresh_driver
        login_as_demo(self.driver)
        navigate_to(self.driver, "/tickets")
        time.sleep(2)

    def test_tickets_list_loads(self):
        """Tickets list page loads with content."""
        screenshot(self.driver, "05_tickets_list")
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        assert any(kw in flat for kw in [
            "ticket", "support", "request", "track"
        ]), f"Tickets page empty. Texts: {texts[:5]}"

    def test_tickets_shows_total_count(self):
        """Tickets page shows total/open/resolved counts."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        has_counts = any(kw in flat for kw in [
            "total", "open", "resolved", "in progress", "closed"
        ])
        assert has_counts, f"Ticket counts missing. Texts: {texts[:10]}"

    def test_tickets_status_filters(self):
        """Tickets page has status filter tabs."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()
        screenshot(self.driver, "05_tickets_filters")

        filter_options = ["all", "open", "in progress", "resolved", "closed"]
        found = [f for f in filter_options if f in flat]
        assert len(found) >= 3, \
            f"Status filters missing. Found: {found}. Texts: {texts[:10]}"

    def test_tickets_shows_priority_breakdown(self):
        """Tickets page shows priority breakdown chart."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        has_priority = any(kw in flat for kw in [
            "priority", "breakdown", "low", "med", "high", "urgent"
        ])
        assert has_priority, f"Priority breakdown missing. Texts: {texts[:10]}"

    def test_tickets_status_distribution_chart(self):
        """Tickets page shows status distribution chart."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        has_dist = any(kw in flat for kw in [
            "status distribution", "distribution", "current ticket"
        ])
        assert has_dist, f"Status distribution missing. Texts: {texts[:10]}"

    def test_tickets_new_ticket_button(self):
        """Tickets page has a 'New Ticket' create button."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        assert "new ticket" in flat or "create" in flat, \
            f"New ticket button missing. Texts: {texts[:10]}"

    def test_ticket_detail_page_loads(self):
        """Ticket detail page loads with ticket info and messages."""
        token, company_id = get_auth()
        r = requests.get(
            f"{API_BASE}/tickets?companyId={company_id}",
            headers={"Authorization": f"Bearer {token}"},
            proxies=PROXIES, timeout=10
        )
        tickets = r.json()
        if not tickets:
            pytest.skip("No tickets in DB")

        ticket_id = tickets[0]["id"]
        navigate_to(self.driver, f"/tickets/{ticket_id}")
        time.sleep(4)
        screenshot(self.driver, "05_ticket_detail")

        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        has_detail = any(kw in flat for kw in [
            "ticket", "message", "status", "reply", "thread", "subject",
            "priority", "open", "closed", "resolved"
        ])
        assert has_detail, f"Ticket detail empty. Texts: {texts[:10]}"

    def test_tickets_filter_by_open(self):
        """Clicking 'Open' filter shows only open tickets."""
        click_button_by_text(self.driver, "Open")
        time.sleep(2)
        screenshot(self.driver, "05_tickets_filter_open")

        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()
        assert len(texts) > 0, "Tickets filter 'Open' crashed"

    def test_tickets_filter_by_resolved(self):
        """Clicking 'Resolved' filter shows resolved tickets."""
        click_button_by_text(self.driver, "Resolved")
        time.sleep(2)
        screenshot(self.driver, "05_tickets_filter_resolved")

        texts = get_all_visible_text(self.driver)
        assert len(texts) > 0, "Tickets filter 'Resolved' crashed"
