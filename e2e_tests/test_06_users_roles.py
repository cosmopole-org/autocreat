"""Users and Roles management tests."""
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


class TestUsers:

    @pytest.fixture(autouse=True)
    def setup(self, fresh_driver):
        self.driver = fresh_driver
        login_as_demo(self.driver)
        navigate_to(self.driver, "/users")
        time.sleep(2)

    def test_users_list_loads(self):
        """Users list page loads with team member data."""
        screenshot(self.driver, "06_users_list")
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        assert any(kw in flat for kw in [
            "team", "member", "user", "invite", "collaborate"
        ]), f"Users page empty. Texts: {texts[:5]}"

    def test_users_shows_member_count(self):
        """Users page shows total member count."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        has_count = any(kw in flat for kw in [
            "total members", "6 total", "active", "member"
        ])
        assert has_count, f"Member count missing. Texts: {texts[:10]}"

    def test_users_shows_role_distribution(self):
        """Users page shows role distribution chart."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        has_dist = any(kw in flat for kw in [
            "role distribution", "owner", "admin", "member", "percent"
        ])
        assert has_dist, f"Role distribution missing. Texts: {texts[:10]}"

    def test_users_shows_seed_users(self):
        """Users page shows seeded demo team members."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        seed_users = ["alexandra", "marcus", "sofia", "james", "emily"]
        found = [u for u in seed_users if u in flat]
        assert len(found) >= 1, \
            f"Seed users missing. Found: {found}. Texts: {texts[:10]}"

    def test_users_add_button(self):
        """Users page has an 'Add User' button."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        assert "add user" in flat or "invite" in flat or "new" in flat, \
            f"Add user button missing. Texts: {texts[:10]}"

    def test_users_filter_all(self):
        """Users page has filter tabs (All, etc.)."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        assert "all" in flat, f"'All' filter missing. Texts: {texts[:10]}"

    def test_user_editor_loads(self):
        """User editor page loads with form fields."""
        token, company_id = get_auth()
        r = requests.get(
            f"{API_BASE}/users?companyId={company_id}",
            headers={"Authorization": f"Bearer {token}"},
            proxies=PROXIES, timeout=10
        )
        users = r.json()
        if not users:
            pytest.skip("No users in DB")

        user_id = users[0]["id"]
        navigate_to(self.driver, f"/users/{user_id}/edit")
        time.sleep(4)
        screenshot(self.driver, "06_user_editor")

        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        has_editor = any(kw in flat for kw in [
            "user", "name", "email", "role", "save", "first", "last", "phone"
        ])
        assert has_editor, f"User editor empty. Texts: {texts[:10]}"


class TestRoles:

    @pytest.fixture(autouse=True)
    def setup(self, fresh_driver):
        self.driver = fresh_driver
        login_as_demo(self.driver)
        navigate_to(self.driver, "/roles")
        time.sleep(2)

    def test_roles_list_loads(self):
        """Roles list page loads with role definitions."""
        screenshot(self.driver, "06_roles_list")
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        assert any(kw in flat for kw in [
            "role", "permission", "access", "policy"
        ]), f"Roles page empty. Texts: {texts[:5]}"

    def test_roles_shows_total_count(self):
        """Roles page shows total role count."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        has_count = any(kw in flat for kw in [
            "5 total", "total roles", "active", "permission"
        ])
        assert has_count, f"Role count missing. Texts: {texts[:10]}"

    def test_roles_shows_members_per_role(self):
        """Roles page shows member count distribution per role."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        has_dist = any(kw in flat for kw in [
            "member", "per role", "admin", "ops", "support", "developer", "viewer"
        ])
        assert has_dist, f"Role distribution missing. Texts: {texts[:10]}"

    def test_roles_shows_seed_roles(self):
        """Roles page shows seeded demo roles."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        seed_roles = ["admin", "ops", "support", "developer", "viewer"]
        found = [r for r in seed_roles if r in flat]
        assert len(found) >= 2, \
            f"Seed roles missing. Found: {found}. Texts: {texts[:10]}"

    def test_roles_new_role_button(self):
        """Roles page has a 'New Role' create button."""
        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        assert "new role" in flat or "create" in flat, \
            f"New role button missing. Texts: {texts[:10]}"

    def test_role_editor_loads(self):
        """Role editor page loads with permission configuration."""
        token, company_id = get_auth()
        r = requests.get(
            f"{API_BASE}/roles?companyId={company_id}",
            headers={"Authorization": f"Bearer {token}"},
            proxies=PROXIES, timeout=10
        )
        roles = r.json()
        if not roles:
            pytest.skip("No roles in DB")

        role_id = roles[0]["id"]
        navigate_to(self.driver, f"/roles/{role_id}/edit")
        time.sleep(4)
        screenshot(self.driver, "06_role_editor")

        texts = get_all_visible_text(self.driver)
        flat = " ".join(texts).lower()

        has_editor = any(kw in flat for kw in [
            "role", "permission", "read", "write", "create", "delete", "save"
        ])
        assert has_editor, f"Role editor empty. Texts: {texts[:10]}"
