from application.services.password_policy import email_error, password_error, username_error


def test_password_requires_length_upper_digit_special():
    assert password_error("") == "Le mot de passe est requis"
    assert "trop court" in password_error("short")
    assert "majuscule" in password_error("nouppercase1!")
    assert "chiffre" in password_error("NoDigitHere!!")
    assert "spécial" in password_error("NoSpecialChar1")
    assert password_error("ValidPassw0rd!") is None


def test_username_allows_accents_and_names_illegal_characters():
    assert username_error("") == "Le nom d'utilisateur est requis"
    assert "Trop court" in username_error("ab")
    assert username_error("ok_user.1") is None
    assert username_error("clément") is None
    assert username_error("Jean-Élie") is None
    assert "espaces" in username_error("jean pierre")
    assert "@" in username_error("user@mail")
    assert "!" in username_error("user!name")


def test_email_errors_are_specific():
    assert email_error("") == "L'adresse e-mail est requise"
    assert "@" in email_error("ada.confidia.local")
    assert "point" in email_error("ada@confidia")
    assert email_error("ada@confidia.local") is None
