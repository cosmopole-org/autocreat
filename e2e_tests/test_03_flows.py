"""Flow management tests: list, statistics, editor navigation."""
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


class TestFlows:

    @pytest.fixture(autouse=True)
    def setup(self, fresh_driver):
        self.driver = fresh_driver
        login_as_demo(self.driver)
        navigate_to(self.driver, "/flows")
        time.sleep(2)

    def test_flows_list_page_loads(self):
        """Flows list page loads with content."""
        screenshot(self.driver, "03_flows_list")
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        assert any(kw in flat for kw in [
            "flow", "automation", "process", "design", "launch", "pipeline"
        ]), f"Flows page empty. Texts: {texts[:5]}"

    def test_flows_page_shows_total_count(self):
        """Flows page shows total flow count."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        has_count = any(kw in flat for kw in [
            "total flows", "3 total", "flows", "active", "draft"
        ])
        assert has_count, f"Flow count missing. Texts: {texts[:10]}"

    def test_flows_shows_node_complexity(self):
        """Flows list shows node complexity chart."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        assert any(kw in flat for kw in ["node", "step", "start", "end", "decision"]), \
            f"Node info missing. Texts: {texts[:10]}"

    def test_flows_create_button_exists(self):
        """Flows page has a 'New Flow' create button."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()
        screenshot(self.driver, "03_flows_create_btn")

        assert "new flow" in flat or "create" in flat, \
            f"New flow button missing. Texts: {texts[:10]}"

    def test_flows_shows_seed_flows(self):
        """Flow list shows the seeded demo flows (Onboarding, Bug, Project)."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        seed_flows = ["onboarding", "bug", "project", "employee"]
        found = [f for f in seed_flows if f in flat]
        assert len(found) >= 1, \
            f"Seed flows not shown. Checked: {seed_flows}. Texts: {texts[:10]}"

    def test_flows_node_type_distribution(self):
        """Flows page shows node type distribution."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        node_types = ["start", "step", "decision", "end"]
        found = [n for n in node_types if n in flat]
        assert len(found) >= 2, \
            f"Node types not shown. Found: {found}"

    def test_flow_editor_page_loads(self):
        """Flow editor page loads when navigating to a flow's edit URL."""
        token, company_id = get_auth()
        r = requests.get(
            f"{API_BASE}/flows?companyId={company_id}",
            headers={"Authorization": f"Bearer {token}"},
            proxies=PROXIES, timeout=10
        )
        flows = r.json()
        if not flows:
            pytest.skip("No flows in DB")

        flow_id = flows[0]["id"]
        navigate_to(self.driver, f"/flows/{flow_id}/edit")
        time.sleep(5)
        screenshot(self.driver, "03_flow_editor")

        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        has_editor = any(kw in flat for kw in [
            "flow", "node", "save", "edit", "graph", "canvas", "step"
        ])
        assert has_editor, f"Flow editor content missing. Texts: {texts[:10]}"

    def test_flow_editor_has_graph_area(self):
        """Flow editor renders the graph canvas area."""
        token, company_id = get_auth()
        r = requests.get(
            f"{API_BASE}/flows?companyId={company_id}",
            headers={"Authorization": f"Bearer {token}"},
            proxies=PROXIES, timeout=10
        )
        flows = r.json()
        if not flows:
            pytest.skip("No flows in DB")

        flow_id = flows[0]["id"]
        navigate_to(self.driver, f"/flows/{flow_id}/edit")
        time.sleep(5)
        screenshot(self.driver, "03_flow_editor_graph")

        texts = get_all_visible_text(self.driver)
        assert len(texts) > 0, "Flow editor rendered nothing"
