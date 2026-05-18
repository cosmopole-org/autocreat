"""API integration tests: verify backend API endpoints work with the UI data."""
import time
import pytest
import requests

API_BASE = "http://localhost:8081/api/v1"
ADMIN_EMAIL = "admin@horizondigital.com"
ADMIN_PASSWORD = "Demo123!"
PROXIES = {"http": None, "https": None}


@pytest.fixture(scope="module")
def auth():
    r = requests.post(
        f"{API_BASE}/auth/login",
        json={"email": ADMIN_EMAIL, "password": ADMIN_PASSWORD},
        proxies=PROXIES, timeout=10
    )
    assert r.status_code == 200, f"Login failed: {r.text}"
    data = r.json()
    return {
        "token": data["accessToken"],
        "refresh_token": data["refreshToken"],
        "user": data["user"],
        "company_id": data["user"]["companyId"],
        "headers": {"Authorization": f"Bearer {data['accessToken']}"}
    }


class TestAPIAuth:

    def test_login_success(self):
        r = requests.post(
            f"{API_BASE}/auth/login",
            json={"email": ADMIN_EMAIL, "password": ADMIN_PASSWORD},
            proxies=PROXIES, timeout=10
        )
        assert r.status_code == 200
        data = r.json()
        assert "accessToken" in data
        assert "refreshToken" in data
        assert "user" in data
        assert data["user"]["email"] == ADMIN_EMAIL

    def test_login_invalid_credentials(self):
        r = requests.post(
            f"{API_BASE}/auth/login",
            json={"email": "bad@email.com", "password": "wrong"},
            proxies=PROXIES, timeout=10
        )
        assert r.status_code == 401

    def test_get_me(self, auth):
        r = requests.get(
            f"{API_BASE}/auth/me",
            headers=auth["headers"],
            proxies=PROXIES, timeout=10
        )
        assert r.status_code == 200
        data = r.json()
        assert data["email"] == ADMIN_EMAIL

    def test_refresh_token(self, auth):
        r = requests.post(
            f"{API_BASE}/auth/refresh",
            json={"refresh_token": auth["refresh_token"]},
            proxies=PROXIES, timeout=10
        )
        assert r.status_code == 200
        data = r.json()
        assert "access_token" in data or "accessToken" in data

    def test_protected_route_without_token(self):
        r = requests.get(
            f"{API_BASE}/auth/me",
            proxies=PROXIES, timeout=10
        )
        assert r.status_code == 401

    def test_register_new_user(self):
        import uuid
        unique_email = f"test_{uuid.uuid4().hex[:8]}@test.com"
        r = requests.post(
            f"{API_BASE}/auth/register",
            json={
                "email": unique_email,
                "password": "Test123!",
                "firstName": "Test",
                "lastName": "User"
            },
            proxies=PROXIES, timeout=10
        )
        assert r.status_code in [200, 201], f"Register failed: {r.text}"
        data = r.json()
        assert "accessToken" in data or "user" in data


class TestAPIFlows:

    def test_list_flows(self, auth):
        r = requests.get(
            f"{API_BASE}/flows?companyId={auth['company_id']}",
            headers=auth["headers"],
            proxies=PROXIES, timeout=10
        )
        assert r.status_code == 200
        data = r.json()
        assert isinstance(data, list)
        assert len(data) >= 1

    def test_get_flow_by_id(self, auth):
        r = requests.get(
            f"{API_BASE}/flows?companyId={auth['company_id']}",
            headers=auth["headers"],
            proxies=PROXIES, timeout=10
        )
        flows = r.json()
        if not flows:
            pytest.skip("No flows")

        flow_id = flows[0]["id"]
        r2 = requests.get(
            f"{API_BASE}/flows/{flow_id}?companyId={auth['company_id']}",
            headers=auth["headers"],
            proxies=PROXIES, timeout=10
        )
        assert r2.status_code == 200
        data = r2.json()
        assert data["id"] == flow_id

    def test_flow_has_nodes(self, auth):
        r = requests.get(
            f"{API_BASE}/flows?companyId={auth['company_id']}",
            headers=auth["headers"],
            proxies=PROXIES, timeout=10
        )
        flows = r.json()
        if not flows:
            pytest.skip("No flows")

        flow_id = flows[0]["id"]
        r2 = requests.get(
            f"{API_BASE}/flows/{flow_id}/nodes?companyId={auth['company_id']}",
            headers=auth["headers"],
            proxies=PROXIES, timeout=10
        )
        assert r2.status_code == 200
        nodes = r2.json()
        assert isinstance(nodes, list)


class TestAPIForms:

    def test_list_forms(self, auth):
        r = requests.get(
            f"{API_BASE}/forms?companyId={auth['company_id']}",
            headers=auth["headers"],
            proxies=PROXIES, timeout=10
        )
        assert r.status_code == 200
        data = r.json()
        assert isinstance(data, list)
        assert len(data) >= 1

    def test_get_form_by_id(self, auth):
        r = requests.get(
            f"{API_BASE}/forms?companyId={auth['company_id']}",
            headers=auth["headers"],
            proxies=PROXIES, timeout=10
        )
        forms = r.json()
        if not forms:
            pytest.skip("No forms")

        form_id = forms[0]["id"]
        r2 = requests.get(
            f"{API_BASE}/forms/{form_id}?companyId={auth['company_id']}",
            headers=auth["headers"],
            proxies=PROXIES, timeout=10
        )
        assert r2.status_code == 200


class TestAPITickets:

    def test_list_tickets(self, auth):
        r = requests.get(
            f"{API_BASE}/tickets?companyId={auth['company_id']}",
            headers=auth["headers"],
            proxies=PROXIES, timeout=10
        )
        assert r.status_code == 200
        data = r.json()
        assert isinstance(data, list)

    def test_create_and_get_ticket(self, auth):
        r = requests.post(
            f"{API_BASE}/tickets",
            json={
                "companyId": auth["company_id"],
                "title": "E2E Test Ticket",
                "description": "Created by Selenium E2E tests",
                "priority": "medium"
            },
            headers=auth["headers"],
            proxies=PROXIES, timeout=10
        )
        assert r.status_code in [200, 201], f"Create ticket failed: {r.text}"
        ticket = r.json()
        ticket_id = ticket.get("id")
        assert ticket_id

        # Verify we can retrieve it
        r2 = requests.get(
            f"{API_BASE}/tickets/{ticket_id}?companyId={auth['company_id']}",
            headers=auth["headers"],
            proxies=PROXIES, timeout=10
        )
        assert r2.status_code == 200
        assert r2.json()["id"] == ticket_id


class TestAPIUsers:

    def test_list_users(self, auth):
        r = requests.get(
            f"{API_BASE}/users?companyId={auth['company_id']}",
            headers=auth["headers"],
            proxies=PROXIES, timeout=10
        )
        assert r.status_code == 200
        data = r.json()
        assert isinstance(data, list)
        assert len(data) >= 1

    def test_admin_user_present(self, auth):
        r = requests.get(
            f"{API_BASE}/users?companyId={auth['company_id']}",
            headers=auth["headers"],
            proxies=PROXIES, timeout=10
        )
        users = r.json()
        emails = [u["email"] for u in users]
        assert ADMIN_EMAIL in emails, f"Admin user not found. Users: {emails}"


class TestAPIRoles:

    def test_list_roles(self, auth):
        r = requests.get(
            f"{API_BASE}/roles?companyId={auth['company_id']}",
            headers=auth["headers"],
            proxies=PROXIES, timeout=10
        )
        assert r.status_code == 200
        data = r.json()
        assert isinstance(data, list)
        assert len(data) >= 1


class TestAPILetters:

    def test_list_letters(self, auth):
        r = requests.get(
            f"{API_BASE}/letters?companyId={auth['company_id']}",
            headers=auth["headers"],
            proxies=PROXIES, timeout=10
        )
        assert r.status_code == 200
        data = r.json()
        assert isinstance(data, list)


class TestAPIModels:

    def test_list_models(self, auth):
        r = requests.get(
            f"{API_BASE}/models?companyId={auth['company_id']}",
            headers=auth["headers"],
            proxies=PROXIES, timeout=10
        )
        assert r.status_code == 200
        data = r.json()
        assert isinstance(data, list)


class TestAPIStats:

    def test_get_dashboard_stats(self, auth):
        r = requests.get(
            f"{API_BASE}/stats?companyId={auth['company_id']}",
            headers=auth["headers"],
            proxies=PROXIES, timeout=10
        )
        assert r.status_code == 200
        data = r.json()
        assert isinstance(data, dict)
        # Stats API returns snake_case keys
        stat_keys = ["total_flows", "total_forms", "total_users", "open_tickets",
                     "totalFlows", "totalForms", "totalUsers", "openTickets"]
        found = [k for k in stat_keys if k in data]
        assert len(found) >= 1, f"Stats missing expected keys. Got: {list(data.keys())}"
