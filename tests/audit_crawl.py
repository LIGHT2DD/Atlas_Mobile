import urllib.request
import urllib.parse
import http.cookiejar
import json

BASE_URL = "http://127.0.0.1:8000"

def audit_client(email, password, role_name):
    print(f"\n=================== AUDITING AS {role_name} ({email}) ===================")
    cj = http.cookiejar.CookieJar()
    opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(cj))
    
    # 1. Login
    login_data = urllib.parse.urlencode({
        "action": "login",
        "email": email,
        "password": password
    }).encode("utf-8")
    
    req = urllib.request.Request(f"{BASE_URL}/auth?mode=login", data=login_data, method="POST")
    try:
        resp = opener.open(req)
        print(f"Login Response: {resp.status} -> {resp.geturl()}")
    except Exception as e:
        print(f"Login Failed: {e}")
        return

    # Check cookies
    cookies = {c.name: c.value for c in cj}
    print(f"Session cookies received: {list(cookies.keys())}")
    
    routes_to_test = [
        "/dashboard/",
        "/dashboard/semesters",
        "/dashboard/teams",
        "/dashboard/requests",
        "/dashboard/proposals",
        "/dashboard/milestones",
        "/dashboard/submissions",
        "/dashboard/defense",
        "/dashboard/rubrics",
        "/dashboard/evaluations",
        "/dashboard/grades",
        "/dashboard/reports",
        "/dashboard/audit-logs",
        "/dashboard/notifications",
        "/dashboard/settings",
        "/dashboard/users",
        "/dashboard/departments",
    ]
    
    for r in routes_to_test:
        req = urllib.request.Request(f"{BASE_URL}{r}", headers={"User-Agent": "AuditTester/1.0"})
        try:
            resp = opener.open(req)
            final_url = resp.geturl()
            status = resp.status
            content = resp.read().decode("utf-8", errors="ignore")
            if "/500" in final_url or "500 Internal" in content:
                print(f" [CRITICAL FAIL 500] {r} -> Redirected to {final_url}")
            elif "/404" in final_url:
                print(f" [NOT FOUND 404] {r} -> Redirected to {final_url}")
            elif final_url.endswith("/dashboard") or final_url == f"{BASE_URL}/":
                print(f" [BLOCKED/REDIRECT] {r} -> {final_url}")
            else:
                print(f" [PASS 200] {r} -> {final_url}")
        except urllib.error.HTTPError as e:
            print(f" [HTTP {e.code}] {r} -> {e.reason}")
        except Exception as e:
            print(f" [EXCEPTION] {r} -> {e}")

if __name__ == "__main__":
    audit_client("coordinator@atlas.edu", "Password123", "COORDINATOR")
    audit_client("supervisor1@atlas.edu", "Password123", "SUPERVISOR")
    audit_client("student1@atlas.edu", "Password123", "STUDENT")
