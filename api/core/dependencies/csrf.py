import secrets
from fastapi import Request, HTTPException
from urllib.parse import urlparse
from api.utils.loggers import create_logger

logger = create_logger(__name__)

CSRF_COOKIE_NAME = "csrf_token"
CSRF_HEADER_NAME = "x-csrf-token"
CSRF_FORM_NAME = "csrf_token"


def generate_csrf_token() -> str:
    """Generate a secure, random CSRF token."""
    return secrets.token_hex(24)


def get_or_create_csrf_token(request: Request) -> tuple[str, bool]:
    """
    Retrieve existing CSRF token from cookie or generate a new one.
    Returns (token, is_new).
    """
    existing_token = request.cookies.get(CSRF_COOKIE_NAME)
    if existing_token and len(existing_token) >= 16:
        return existing_token, False
    return generate_csrf_token(), True


def verify_csrf_request(request: Request) -> bool:
    """
    Verify CSRF protection for mutating requests.
    Validates Double Submit Cookie, X-CSRF-Token header, or Same-Origin headers.
    Returns True if valid, raises HTTPException(403) or returns False otherwise.
    """
    if request.method in ("GET", "HEAD", "OPTIONS"):
        return True

    # Exempt REST API endpoints (mobile & API clients use JSON payloads & JWT)
    if request.url.path.startswith("/api/"):
        return True

    # Allow requests authenticated via Authorization header (API / programmatic clients)
    if request.headers.get("authorization", "").startswith("Bearer "):
        return True

    # 1. Double Submit Cookie verification (via header or state)
    cookie_token = request.cookies.get(CSRF_COOKIE_NAME)
    header_token = request.headers.get(CSRF_HEADER_NAME)

    if cookie_token and header_token and secrets.compare_digest(cookie_token, header_token):
        return True

    # 2. Origin / Referer validation (OWASP recommended same-origin defense)
    origin = request.headers.get("origin")
    referer = request.headers.get("referer")
    host = request.headers.get("host")

    target_header = origin or referer
    if target_header and host:
        parsed = urlparse(target_header)
        origin_host = parsed.netloc
        if origin_host and origin_host.lower() == host.lower():
            return True
        logger.warning(f"CSRF origin mismatch: header host={host}, origin={origin_host}")
        raise HTTPException(status_code=403, detail="Cross-Site Request Forgery detected: Origin mismatch.")

    return True
