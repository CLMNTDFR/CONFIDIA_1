import re

MIN_LENGTH = 12
MIN_USERNAME = 3
MAX_USERNAME = 32
UPPERCASE = re.compile(r"[A-Z]")
DIGIT = re.compile(r"\d")
SPECIAL = re.compile(r"[^A-Za-z0-9]")
USERNAME_CHAR = re.compile(r"^[\w.\-]$", re.UNICODE)
USERNAME_FULL = re.compile(r"^[\w.\-]+$", re.UNICODE)
EMAIL_PATTERN = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


def password_error(password: str) -> str | None:
    if password == "":
        return "Le mot de passe est requis"
    if len(password) < MIN_LENGTH:
        n = len(password)
        unit = "caractère" if n == 1 else "caractères"
        return f"Le mot de passe est trop court ({n} {unit}). Minimum : {MIN_LENGTH}."
    if not UPPERCASE.search(password):
        return "Il manque au moins une lettre majuscule (A-Z)."
    if not DIGIT.search(password):
        return "Il manque au moins un chiffre (0-9)."
    if not SPECIAL.search(password):
        return "Il manque au moins un caractère spécial (par exemple ! ? # @)."
    return None


def username_error(username: str) -> str | None:
    raw = username
    value = username.strip()
    if raw == "":
        return "Le nom d'utilisateur est requis"
    if value == "":
        return "Le nom d'utilisateur ne peut pas contenir uniquement des espaces"
    if raw != value:
        return "Retirez les espaces avant ou après le nom d'utilisateur"
    if any(ch.isspace() for ch in value):
        return "Les espaces ne sont pas autorisés dans le nom d'utilisateur"
    if "@" in value:
        return (
            "Le caractère « @ » n'est pas autorisé ici. "
            "Saisissez un identifiant, pas une adresse e-mail."
        )
    length = len(value)
    if length < MIN_USERNAME:
        unit = "caractère" if length == 1 else "caractères"
        return f"Trop court : {length} {unit} (minimum {MIN_USERNAME})."
    if length > MAX_USERNAME:
        return f"Trop long : {length} caractères (maximum {MAX_USERNAME})."
    if not USERNAME_FULL.fullmatch(value):
        for ch in value:
            if not USERNAME_CHAR.fullmatch(ch):
                return (
                    f"Le caractère « {ch} » n'est pas autorisé. "
                    "Lettres (accents compris), chiffres, point, tiret et underscore uniquement."
                )
        return (
            "Lettres (accents compris), chiffres, point, tiret et underscore uniquement."
        )
    return None


def email_error(email: str) -> str | None:
    raw = email
    value = email.strip()
    if raw == "":
        return "L'adresse e-mail est requise"
    if value == "":
        return "L'adresse e-mail ne peut pas contenir uniquement des espaces"
    if any(ch.isspace() for ch in value):
        return "Les espaces ne sont pas autorisés dans l'adresse e-mail"
    if "@" not in value:
        return "Il manque le caractère @. Exemple : prenom@domaine.fr"
    if value.count("@") > 1:
        return "Une adresse e-mail ne peut contenir qu'un seul @"
    local, _, domain = value.partition("@")
    if not local:
        return "Indiquez la partie avant @ (exemple : prenom@domaine.fr)"
    if not domain:
        return "Indiquez le domaine après @ (exemple : prenom@domaine.fr)"
    if "." not in domain:
        return "Le domaine doit contenir un point (exemple : domaine.fr)"
    if domain.startswith(".") or domain.endswith("."):
        return "Le domaine de l'adresse e-mail est incomplet"
    if not EMAIL_PATTERN.fullmatch(value):
        return "Cette adresse e-mail n'est pas reconnue. Vérifiez le format (prenom@domaine.fr)."
    return None
