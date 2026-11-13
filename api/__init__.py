# Passlib 1.7.4 compatibility patch for bcrypt >= 4.0.0
try:
    import bcrypt
    if not hasattr(bcrypt, '__about__'):
        class _About:
            __version__ = getattr(bcrypt, '__version__', '4.0.1')
        bcrypt.__about__ = _About()

    _orig_hashpw = bcrypt.hashpw
    def _safe_hashpw(password, salt):
        if isinstance(password, (bytes, bytearray)) and len(password) > 72:
            password = password[:72]
        return _orig_hashpw(password, salt)
    bcrypt.hashpw = _safe_hashpw
except ImportError:
    pass
