"""Selenium E2E test configuration for Flutter Web (CanvasKit release build).

Flutter Web CanvasKit renders to an offscreen GPU canvas. The DOM has:
- flt-semantics elements as accessibility overlays (interact via these)
- real <input> elements in flt-text-editing-host (active only when text field focused)
- innerText on flt-semantics is readable and contains button/label text
- aria-label is set only on checkboxes and specifically labeled elements
"""
import os
import subprocess
import time
import pytest
import requests as _requests
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException

API_BASE = "http://localhost:8081/api/v1"
_PROXIES = {"http": None, "https": None}
_SERVER_PROC = None
_WEB_PROC = None


def _ensure_go_server():
    """Start the Go API server if not already listening on 8081."""
    import socket
    try:
        s = socket.create_connection(("localhost", 8081), timeout=2)
        s.close()
        return
    except OSError:
        pass
    global _SERVER_PROC
    _SERVER_PROC = subprocess.Popen(
        ["./bin/server"],
        cwd="/home/keyhan/autocreat/server",
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        env={**os.environ, "NO_PROXY": "localhost,127.0.0.1"},
    )
    time.sleep(3)


def _ensure_web_server():
    """Start the Flutter web static server if not already listening on 9090."""
    import socket
    try:
        s = socket.create_connection(("localhost", 9090), timeout=2)
        s.close()
        return
    except OSError:
        pass
    global _WEB_PROC
    _WEB_PROC = subprocess.Popen(
        ["python3", "-m", "http.server", "9090"],
        cwd="/home/keyhan/autocreat/client/build/web",
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        env={**os.environ, "NO_PROXY": "localhost,127.0.0.1"},
    )
    time.sleep(2)


def pytest_configure(config):
    os.environ.setdefault("DISPLAY", ":0")
    os.environ.setdefault("NO_PROXY", "localhost,127.0.0.1")
    os.environ.setdefault("no_proxy", "localhost,127.0.0.1")
    _ensure_go_server()
    _ensure_web_server()

# Release build served at port 9090 with local CanvasKit (patched bootstrap)
APP_URL = "http://localhost:9090"
ADMIN_EMAIL = "admin@horizondigital.com"
ADMIN_PASSWORD = "Demo123!"
DEMO_EMAIL = "demo@autocreat.io"

CHROMEDRIVER_PATH = "/home/keyhan/.wdm/drivers/chromedriver/linux64/142.0.7444.175/chromedriver-linux64/chromedriver"
SCREENSHOTS_DIR = os.path.join(os.path.dirname(__file__), "screenshots")


def _build_options(window_size="1440,900"):
    opts = Options()
    opts.add_argument("--headless=new")          # headless Chrome
    opts.add_argument("--no-sandbox")
    opts.add_argument("--disable-dev-shm-usage")
    opts.add_argument(f"--window-size={window_size}")
    opts.add_argument("--no-proxy-server")
    # SwiftShader: software WebGL required for Flutter CanvasKit in WSL2
    opts.add_argument("--enable-unsafe-swiftshader")
    opts.add_argument("--use-gl=swiftshader")
    opts.add_argument("--enable-webgl")
    opts.add_argument("--disable-extensions")
    opts.add_argument("--disable-gpu")
    return opts


def get_driver(window_size="1440,900"):
    opts = _build_options(window_size)
    service = Service(executable_path=CHROMEDRIVER_PATH)
    d = webdriver.Chrome(service=service, options=opts)
    d.set_page_load_timeout(30)
    return d


@pytest.fixture(scope="session")
def driver():
    os.makedirs(SCREENSHOTS_DIR, exist_ok=True)
    d = get_driver()
    yield d
    d.quit()


@pytest.fixture(scope="function")
def fresh_driver():
    os.makedirs(SCREENSHOTS_DIR, exist_ok=True)
    d = get_driver()
    yield d
    d.quit()


def enable_accessibility(driver):
    """Click the Flutter accessibility placeholder to enable the semantics tree."""
    try:
        driver.execute_script("""
            var btn = document.querySelector('flt-semantics-placeholder');
            if (btn) btn.click();
        """)
        time.sleep(1.5)
    except Exception:
        pass


def wait_for_flutter(driver, timeout=25):
    """Wait until Flutter has rendered its first frame, then enable accessibility."""
    try:
        WebDriverWait(driver, timeout).until(lambda d: d.execute_script("""
            var loading = document.getElementById('loading');
            return loading && loading.style.display === 'none';
        """))
    except TimeoutException:
        try:
            WebDriverWait(driver, 5).until(lambda d: d.execute_script(
                "return document.querySelector('flutter-view') !== null;"
            ))
        except TimeoutException:
            pass
    enable_accessibility(driver)
    time.sleep(1.5)


def screenshot(driver, name):
    os.makedirs(SCREENSHOTS_DIR, exist_ok=True)
    path = os.path.join(SCREENSHOTS_DIR, f"{name}.png")
    driver.save_screenshot(path)
    return path


def get_all_visible_text(driver):
    """Get all visible text from flt-semantics elements (leaf nodes preferred)."""
    return driver.execute_script("""
        var all = Array.from(document.querySelectorAll('flt-semantics'));
        var texts = new Set();
        // Collect aria-labels
        all.forEach(function(el) {
            var label = el.getAttribute('aria-label');
            if (label && label.trim()) texts.add(label.trim());
        });
        // Collect innerText from leaf-like elements (no children or few children)
        all.forEach(function(el) {
            var children = el.querySelectorAll('flt-semantics').length;
            var t = (el.innerText || '').trim();
            if (t && t.length < 300) texts.add(t);
        });
        return Array.from(texts);
    """) or []


def click_button_by_text(driver, text, timeout=8):
    """Click a flt-semantics button whose innerText includes the given text."""
    wait = WebDriverWait(driver, timeout)
    try:
        result = wait.until(lambda d: d.execute_script(f"""
            var btns = document.querySelectorAll('flt-semantics[role="button"]');
            for (var btn of btns) {{
                var inner = (btn.innerText || '').toLowerCase();
                var label = (btn.getAttribute('aria-label') || '').toLowerCase();
                if (inner.includes('{text.lower()}') || label.includes('{text.lower()}')) {{
                    btn.click(); return btn.innerText || btn.getAttribute('aria-label');
                }}
            }}
            return null;
        """))
        return result is not None
    except TimeoutException:
        return False


def click_checkbox_by_label(driver, label_text, timeout=8):
    """Click a flt-semantics checkbox with a given aria-label."""
    wait = WebDriverWait(driver, timeout)
    try:
        result = wait.until(lambda d: d.execute_script(f"""
            var checks = document.querySelectorAll('flt-semantics[role="checkbox"]');
            for (var c of checks) {{
                var label = (c.getAttribute('aria-label') || '');
                if (label.includes('{label_text}')) {{ c.click(); return label; }}
            }}
            return null;
        """))
        return result is not None
    except TimeoutException:
        return False


def get_inputs(driver):
    """Get real HTML input elements."""
    return driver.find_elements(By.CSS_SELECTOR, "input")


def navigate_to(driver, route):
    """Navigate to a Flutter route without a page reload.

    Uses pushState + a synthetic popstate event so GoRouter's HashUrlStrategy
    listener is triggered (it listens to popstate, not hashchange).
    """
    route_path = route if route.startswith('/') else f'/{route}'
    driver.execute_script(
        f"window.history.pushState(null, '', '/#{ route_path }');"
        "window.dispatchEvent(new PopStateEvent('popstate', {state: null}));"
    )
    time.sleep(2)
    wait_for_flutter(driver)


def login_as_admin(driver):
    """Login as admin by injecting a real JWT token into localStorage."""
    login_as_demo(driver)


def login_as_demo(driver):
    """Login by clicking 'Try Demo Mode' in Flutter's login UI.

    This uses the actual Flutter login screen so that the app's own auth flow
    stores the JWT tokens.  It avoids the localStorage-injection approach whose
    tokens are invisible to Flutter's dart2js compiled code (package:web's
    window.localStorage resolves to a different object in that scope).
    """
    driver.get(APP_URL)
    wait_for_flutter(driver, timeout=30)
    time.sleep(2)

    # Click "Try Demo Mode" — now calls the real API login (admin credentials)
    # and stores tokens through Flutter's own TokenStorage / auth flow.
    clicked = click_button_by_text(driver, "Try Demo Mode", timeout=12)
    if not clicked:
        # Fall back: try typing credentials and clicking Login
        from selenium.webdriver.common.keys import Keys
        type_into_flutter_field(driver, ADMIN_EMAIL, 0)
        time.sleep(0.5)
        type_into_flutter_field(driver, ADMIN_PASSWORD, 1)
        time.sleep(0.5)
        click_button_by_text(driver, "Login", timeout=8)

    # Wait for the auth flow to complete and the router to navigate away from login
    time.sleep(6)
    wait_for_flutter(driver, timeout=20)

    final_url = driver.current_url
    if '/login' in final_url:
        raise RuntimeError(
            f"login_as_demo: authentication failed — still on {final_url}. "
            "Check that the Go server is running and that 'Try Demo Mode' calls the real login API."
        )


# ── Text-input helpers (Flutter CanvasKit pattern) ─────────────────────────

def type_into_flutter_field(driver, text, field_index=0):
    """Click the nth Flutter textbox and type text into the real HTML input.

    Flutter Web creates a real <input> inside flt-text-editing-host when a
    text field is focused. We click the flt-semantics textbox to trigger that,
    then type into the real input element.
    """
    from selenium.webdriver.common.keys import Keys
    driver.execute_script(f"""
        var fields = Array.from(document.querySelectorAll('flt-semantics[role="textbox"]'));
        if (fields[{field_index}]) fields[{field_index}].click();
    """)
    time.sleep(0.8)
    try:
        inp = WebDriverWait(driver, 5).until(
            EC.presence_of_element_located((By.CSS_SELECTOR,
                'flt-text-editing-host input, flt-text-editing-host textarea'))
        )
        inp.send_keys(Keys.CONTROL + 'a')
        inp.send_keys(text)
        return True
    except TimeoutException:
        inputs = driver.find_elements(By.CSS_SELECTOR, 'input:not([type="hidden"])')
        if inputs:
            inputs[0].send_keys(Keys.CONTROL + 'a')
            inputs[0].send_keys(text)
            return True
    return False


def count_textfields(driver):
    """Return number of Flutter textbox semantics elements visible."""
    result = driver.execute_script(
        "return document.querySelectorAll('flt-semantics[role=\"textbox\"]').length;"
    )
    return result or 0


def press_enter(driver):
    """Press Enter on the currently active Flutter input."""
    from selenium.webdriver.common.keys import Keys
    inputs = driver.find_elements(By.CSS_SELECTOR,
        'flt-text-editing-host input, flt-text-editing-host textarea, input:not([type="hidden"])')
    if inputs:
        inputs[0].send_keys(Keys.RETURN)
        return True
    return False


def wait_for_url_change(driver, old_url, timeout=15):
    """Wait until the current URL differs from old_url (navigation happened)."""
    try:
        WebDriverWait(driver, timeout).until(lambda d: d.current_url != old_url)
        return True
    except TimeoutException:
        return False


def click_element_by_text(driver, text, role=None, timeout=8):
    """Click any flt-semantics element whose text or aria-label contains text.

    More permissive than click_button_by_text — works for list-items, tabs,
    chips, and any other semantic element that isn't role=button.
    """
    selector = f'flt-semantics[role="{role}"]' if role else 'flt-semantics'
    wait = WebDriverWait(driver, timeout)
    try:
        result = wait.until(lambda d: d.execute_script(f"""
            var els = document.querySelectorAll('{selector}');
            var q = '{text.lower()}';
            for (var el of els) {{
                var inner = (el.innerText || '').toLowerCase();
                var label = (el.getAttribute('aria-label') || '').toLowerCase();
                if (inner === q || label === q || inner.includes(q) || label.includes(q)) {{
                    el.click(); return inner || label;
                }}
            }}
            return null;
        """))
        return result is not None
    except TimeoutException:
        return False
