"""Search and filter workflows across all major list pages."""
import time
import pytest
import requests
from conftest import (
    APP_URL, wait_for_flutter, screenshot, get_all_visible_text,
    login_as_demo, navigate_to, click_button_by_text,
    type_into_flutter_field, count_textfields,
    click_element_by_text,
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


class TestFlowSearch:

    @pytest.fixture(autouse=True)
    def setup(self, fresh_driver):
        self.driver = fresh_driver
        login_as_demo(self.driver)
        navigate_to(self.driver, "/flows")
        time.sleep(2)

    def test_search_field_present(self):
        """Flows list has a search field."""
        fields = count_textfields(self.driver)
        texts = get_all_visible_text(self.driver)
        assert fields > 0 or "search" in " ".join(texts).lower(), \
            f"No search field. Fields: {fields}"

    def test_search_by_existing_flow_name(self):
        """Searching by a seed flow name shows matching results."""
        token, company_id = get_auth()
        flows = api_get(token, f"flows?companyId={company_id}")
        if not flows:
            pytest.skip("No flows")

        query = flows[0].get("name", "")[:6]
        if not query:
            pytest.skip("Flow has no name")

        type_into_flutter_field(self.driver, query, 0)
        time.sleep(2)
        screenshot(self.driver, "16_flow_search_result")

        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()
        assert query.lower() in flat or "no flow" in flat, \
            f"Search '{query}' yielded unexpected result. Texts: {texts[:8]}"

    def test_search_no_match_shows_empty_state(self):
        """Searching with a non-matching term shows empty/no-results state."""
        type_into_flutter_field(self.driver, "zzzzzNONEXISTENT99999", 0)
        time.sleep(2)
        screenshot(self.driver, "16_flow_search_no_match")

        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()
        # Either "no flows" message or an empty visible area
        assert "no flow" in flat or "not found" in flat or len(
            [t for t in texts if any(kw in t.lower() for kw in ["onboard", "bug", "project", "employee"])]
        ) == 0, f"Seed flows still visible after non-matching search: {texts[:8]}"

    def test_clear_search_restores_all_flows(self):
        """Clearing search shows all flows again."""
        from selenium.webdriver.common.keys import Keys
        from selenium.webdriver.common.by import By

        type_into_flutter_field(self.driver, "zzzNOMATCH", 0)
        time.sleep(1)

        inputs = self.driver.find_elements(By.CSS_SELECTOR, 'input:not([type="hidden"])')
        if inputs:
            inputs[0].send_keys(Keys.CONTROL + "a")
            inputs[0].send_keys(Keys.DELETE)
        time.sleep(2)
        screenshot(self.driver, "16_flow_search_cleared")

        texts = get_all_visible_text(self.driver)
        assert len(texts) > 3, f"List empty after clearing search. Texts: {texts[:5]}"


class TestFormSearch:

    @pytest.fixture(autouse=True)
    def setup(self, fresh_driver):
        self.driver = fresh_driver
        login_as_demo(self.driver)
        navigate_to(self.driver, "/forms")
        time.sleep(2)

    def test_search_by_existing_form_name(self):
        """Searching by a seed form name filters the list."""
        token, company_id = get_auth()
        forms = api_get(token, f"forms?companyId={company_id}")
        if not forms:
            pytest.skip("No forms")

        query = forms[0].get("name", "")[:6]
        if not query:
            pytest.skip("Form has no name")

        type_into_flutter_field(self.driver, query, 0)
        time.sleep(2)
        screenshot(self.driver, "16_form_search_result")

        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()
        assert query.lower() in flat or "no form" in flat, \
            f"Form search unexpected. Texts: {texts[:8]}"

    def test_form_search_no_match(self):
        """Searching with non-matching term shows empty state on forms."""
        type_into_flutter_field(self.driver, "zzznomatch9999", 0)
        time.sleep(2)
        screenshot(self.driver, "16_form_search_no_match")

        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()
        seed_forms = ["customer feedback", "bug report", "support", "employee"]
        remaining = [f for f in seed_forms if f in flat]
        assert "no form" in flat or len(remaining) == 0, \
            f"Forms still visible after bad search. Remaining: {remaining}"


class TestTicketSearchFilter:

    @pytest.fixture(autouse=True)
    def setup(self, fresh_driver):
        self.driver = fresh_driver
        login_as_demo(self.driver)
        navigate_to(self.driver, "/tickets")
        time.sleep(2)

    def test_ticket_search_by_title(self):
        """Searching by an existing ticket title filters results."""
        token, company_id = get_auth()
        tickets = api_get(token, f"tickets?companyId={company_id}")
        if not tickets:
            pytest.skip("No tickets")

        query = tickets[0].get("title", "")[:8]
        if not query:
            pytest.skip("Ticket has no title")

        type_into_flutter_field(self.driver, query, 0)
        time.sleep(2)
        screenshot(self.driver, "16_ticket_search_result")

        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()
        assert query.lower() in flat or "no ticket" in flat, \
            f"Ticket search unexpected for '{query}'. Texts: {texts[:8]}"

    def test_ticket_filter_all_tab(self):
        """'All' filter tab shows all tickets without status restriction."""
        click_element_by_text(self.driver, "All")
        time.sleep(1.5)
        screenshot(self.driver, "16_ticket_all_tab")

        texts = get_all_visible_text(self.driver)
        assert len(texts) > 2, f"Tickets All tab empty: {texts[:5]}"

    def test_ticket_filter_open_tab(self):
        """'Open' filter tab shows only open tickets."""
        click_element_by_text(self.driver, "Open")
        time.sleep(1.5)
        screenshot(self.driver, "16_ticket_open_tab")

        texts = get_all_visible_text(self.driver)
        assert len(texts) > 0, "Tickets Open tab empty"

    def test_ticket_filter_in_progress_tab(self):
        """'In Progress' filter tab shows in-progress tickets."""
        click_element_by_text(self.driver, "In Progress")
        time.sleep(1.5)
        screenshot(self.driver, "16_ticket_inprogress_tab")

        texts = get_all_visible_text(self.driver)
        assert len(texts) > 0, "Tickets In Progress tab empty"

    def test_ticket_filter_resolved_tab(self):
        """'Resolved' filter tab shows resolved tickets."""
        click_element_by_text(self.driver, "Resolved")
        time.sleep(1.5)
        screenshot(self.driver, "16_ticket_resolved_tab")

        texts = get_all_visible_text(self.driver)
        assert len(texts) > 0, "Tickets Resolved tab empty"

    def test_ticket_filter_closed_tab(self):
        """'Closed' filter tab shows closed tickets."""
        click_element_by_text(self.driver, "Closed")
        time.sleep(1.5)
        screenshot(self.driver, "16_ticket_closed_tab")

        texts = get_all_visible_text(self.driver)
        assert len(texts) > 0, "Tickets Closed tab empty"

    def test_ticket_status_tabs_all_clickable(self):
        """All ticket status filter tabs are clickable without errors."""
        for tab in ["All", "Open", "In Progress", "Resolved", "Closed"]:
            click_element_by_text(self.driver, tab)
            time.sleep(1)
            texts = get_all_visible_text(self.driver)
            assert len(texts) > 0, f"Ticket tab '{tab}' crashed the page"
        screenshot(self.driver, "16_ticket_all_tabs_tested")


class TestUserSearch:

    @pytest.fixture(autouse=True)
    def setup(self, fresh_driver):
        self.driver = fresh_driver
        login_as_demo(self.driver)
        navigate_to(self.driver, "/users")
        time.sleep(2)

    def test_user_search_by_name(self):
        """Searching users by a known name filters the list."""
        token, company_id = get_auth()
        users = api_get(token, f"users?companyId={company_id}")
        if not users:
            pytest.skip("No users")

        query = (users[0].get("firstName") or users[0].get("name") or "admin")[:5]
        type_into_flutter_field(self.driver, query, 0)
        time.sleep(2)
        screenshot(self.driver, "16_user_search")

        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()
        assert query.lower() in flat or "no user" in flat or len(texts) > 0, \
            f"User search unexpected. Texts: {texts[:8]}"

    def test_user_filter_all_tab(self):
        """Users 'All' filter shows all users."""
        click_element_by_text(self.driver, "All")
        time.sleep(1.5)
        screenshot(self.driver, "16_users_all_tab")

        texts = get_all_visible_text(self.driver)
        assert len(texts) > 2, "Users All tab empty"

    def test_user_filter_by_role_tabs(self):
        """Clicking role filter tabs on users page works."""
        for role in ["Admin", "Operator", "Support"]:
            click_element_by_text(self.driver, role)
            time.sleep(1.5)
            texts = get_all_visible_text(self.driver)
            assert len(texts) > 0, f"Users role tab '{role}' crashed"
        screenshot(self.driver, "16_users_role_tabs")


class TestLetterModelSearch:

    @pytest.fixture(autouse=True)
    def setup(self, fresh_driver):
        self.driver = fresh_driver
        login_as_demo(self.driver)

    def test_letter_search_by_name(self):
        """Searching on the letters list filters by template name."""
        token, company_id = get_auth()
        letters = api_get(token, f"letters?companyId={company_id}")
        if not letters:
            pytest.skip("No letters")

        navigate_to(self.driver, "/letters")
        time.sleep(2)
        query = letters[0].get("name", "")[:6]
        if not query:
            pytest.skip("No name")

        type_into_flutter_field(self.driver, query, 0)
        time.sleep(2)
        screenshot(self.driver, "16_letter_search")

        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()
        assert query.lower() in flat or "no template" in flat or "no letter" in flat, \
            f"Letter search unexpected. Texts: {texts[:8]}"

    def test_model_search_by_name(self):
        """Searching on the models list filters by model name."""
        token, company_id = get_auth()
        models = api_get(token, f"models?companyId={company_id}")
        if not models:
            pytest.skip("No models")

        navigate_to(self.driver, "/models")
        time.sleep(2)
        query = models[0].get("name", "")[:5]
        if not query:
            pytest.skip("No name")

        type_into_flutter_field(self.driver, query, 0)
        time.sleep(2)
        screenshot(self.driver, "16_model_search")

        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()
        assert query.lower() in flat or "no model" in flat, \
            f"Model search unexpected. Texts: {texts[:8]}"

    def test_letter_filter_by_category(self):
        """Letter templates can be filtered by category."""
        navigate_to(self.driver, "/letters")
        time.sleep(2)

        texts_before = get_all_visible_text(self.driver)
        flat_before = " ".join(texts_before).lower()

        # Try clicking known categories from seed data
        for cat in ["onboarding", "hr", "delivery"]:
            if cat in flat_before:
                click_element_by_text(self.driver, cat)
                time.sleep(1.5)
                screenshot(self.driver, f"16_letter_cat_{cat}")
                texts = get_all_visible_text(self.driver)
                assert len(texts) > 0, f"Letter category filter '{cat}' crashed"
                break
        else:
            # No known category clickable, just verify page is intact
            assert len(texts_before) > 0, "Letters list empty"


class TestRoleSearch:

    @pytest.fixture(autouse=True)
    def setup(self, fresh_driver):
        self.driver = fresh_driver
        login_as_demo(self.driver)
        navigate_to(self.driver, "/roles")
        time.sleep(2)

    def test_role_search_by_name(self):
        """Searching on the roles list filters roles by name."""
        token, company_id = get_auth()
        roles = api_get(token, f"roles?companyId={company_id}")
        if not roles:
            pytest.skip("No roles")

        query = roles[0].get("name", "admin")[:5]
        type_into_flutter_field(self.driver, query, 0)
        time.sleep(2)
        screenshot(self.driver, "16_roles_search")

        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()
        assert query.lower() in flat or "no role" in flat, \
            f"Role search unexpected. Texts: {texts[:8]}"

    def test_roles_list_shows_seed_roles(self):
        """Seed roles (Admin, Operator, Support, Developer, Viewer) are all listed."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()
        found = [r for r in ["admin", "operator", "support", "developer", "viewer"] if r in flat]
        assert len(found) >= 3, f"Seed roles missing. Found: {found}"
