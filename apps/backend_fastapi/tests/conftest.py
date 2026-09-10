"""Isolate JWT tests from development settings cached by get_settings()."""

from __future__ import annotations

import os

os.environ["APP_ENV"] = "test"

import pytest

from core.config import get_settings
from core.security import clear_jwks_cache


@pytest.fixture(autouse=True)
def _reset_security_caches():
    get_settings.cache_clear()
    clear_jwks_cache()
    yield
    get_settings.cache_clear()
    clear_jwks_cache()
