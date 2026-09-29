import hashlib
import secrets
from datetime import timedelta

from django.contrib.auth.models import AbstractUser, BaseUserManager
from django.db import models
from django.utils import timezone


def sha256(value: str) -> str:
    return hashlib.sha256(value.encode()).hexdigest()


class UserManager(BaseUserManager):
    use_in_migrations = True

    def create_user(self, email, password=None, **extra):
        user = self.model(email=self.normalize_email(email).lower(), **extra)
        user.set_password(password) if password else user.set_unusable_password()
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra):
        extra.update(is_staff=True, is_superuser=True)
        return self.create_user(email, password, **extra)


class User(AbstractUser):
    """A person, identified by email. No passwords: sign-in is by emailed
    code or by Google."""

    username = None
    email = models.EmailField(unique=True)

    # Per-account secret behind approximate locations, shared by all the
    # person's devices so the same spot hides the same way everywhere.
    privacy_secret = models.CharField(max_length=64, blank=True)

    # Consent: anonymous totals of trips linked to a venue may be shown to
    # that venue (never who, never where exactly). Off until the person
    # turns it on.
    share_insights = models.BooleanField(default=False)

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = []

    objects = UserManager()


class EmailCode(models.Model):
    """A one-time sign-in code sent by email. Only its hash is stored."""

    TTL = timedelta(minutes=10)
    MAX_ATTEMPTS = 5

    email = models.EmailField(db_index=True)
    code_hash = models.CharField(max_length=64)
    created_at = models.DateTimeField(default=timezone.now)
    attempts = models.PositiveSmallIntegerField(default=0)
    used = models.BooleanField(default=False)

    def __str__(self) -> str:
        return f"code for {self.email}"

    @classmethod
    def issue(cls, email: str) -> str:
        code = f"{secrets.randbelow(1_000_000):06d}"
        cls.objects.create(email=email, code_hash=sha256(f"{email}:{code}"))
        return code

    @property
    def expired(self) -> bool:
        return timezone.now() - self.created_at > self.TTL

    def matches(self, code: str) -> bool:
        return secrets.compare_digest(self.code_hash, sha256(f"{self.email}:{code}"))


class AuthToken(models.Model):
    """One per signed-in device. The raw token is shown once; only its hash
    is stored, so a database leak does not leak sessions."""

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="tokens")
    key_hash = models.CharField(max_length=64, unique=True)
    device = models.CharField(max_length=80, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    last_used_at = models.DateTimeField(null=True, blank=True)

    def __str__(self) -> str:
        return f"token of {self.user_id} ({self.device})"

    @classmethod
    def issue(cls, user: User, device: str = "") -> str:
        raw = secrets.token_urlsafe(32)
        cls.objects.create(user=user, key_hash=sha256(raw), device=device[:80])
        return raw
