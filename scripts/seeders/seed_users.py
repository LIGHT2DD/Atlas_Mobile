"""
Seed script to populate the database with test users.

All users share the same password: Password123

Usage:
    python -m scripts.seeders.seed_users

Roles seeded:
    - 2 Admin users
    - 4 Supervisor users
    - 6 Student users
"""

import sys
import os

# Ensure the project root is on the path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..')))

from passlib.context import CryptContext
from api.db.database import get_db_with_ctx_manager, create_database
from api.v1.models.user import User, UserRole

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# ──────────────────────────────────────────────
#  Shared password for every seeded user
# ──────────────────────────────────────────────
SEED_PASSWORD = "Password123"

USERS = [
    # ── Admins ────────────────────────────────
    {
        "first_name": "Adebayo",
        "last_name": "Ogunleye",
        "email": "admin@atlas.edu",
        "role": UserRole.ADMIN.value,
        "is_active": True,
    },
    {
        "first_name": "Funke",
        "last_name": "Adeyemi",
        "email": "admin2@atlas.edu",
        "role": UserRole.ADMIN.value,
        "is_active": True,
    },

    # ── Supervisors ───────────────────────────
    {
        "first_name": "Dr. Chinedu",
        "last_name": "Okafor",
        "email": "supervisor1@atlas.edu",
        "role": UserRole.SUPERVISOR.value,
        "is_active": True,
    },
    {
        "first_name": "Prof. Ngozi",
        "last_name": "Eze",
        "email": "supervisor2@atlas.edu",
        "role": UserRole.SUPERVISOR.value,
        "is_active": True,
    },
    {
        "first_name": "Dr. Tunde",
        "last_name": "Bakare",
        "email": "supervisor3@atlas.edu",
        "role": UserRole.SUPERVISOR.value,
        "is_active": True,
    },
    {
        "first_name": "Dr. Amina",
        "last_name": "Ibrahim",
        "email": "supervisor4@atlas.edu",
        "role": UserRole.SUPERVISOR.value,
        "is_active": True,
    },
    {
        "first_name": "Prof. Segun",
        "last_name": "Adeniyi",
        "email": "supervisor5@atlas.edu",
        "role": UserRole.SUPERVISOR.value,
        "is_active": True,
    },

    # ── Students ──────────────────────────────
    {
        "first_name": "Korede",
        "last_name": "Fashina",
        "email": "student1@atlas.edu",
        "role": UserRole.STUDENT.value,
        "is_active": True,
    },
    {
        "first_name": "Chiamaka",
        "last_name": "Nwosu",
        "email": "student2@atlas.edu",
        "role": UserRole.STUDENT.value,
        "is_active": True,
    },
    {
        "first_name": "Yusuf",
        "last_name": "Abdullahi",
        "email": "student3@atlas.edu",
        "role": UserRole.STUDENT.value,
        "is_active": True,
    },
    {
        "first_name": "Temitope",
        "last_name": "Akinwale",
        "email": "student4@atlas.edu",
        "role": UserRole.STUDENT.value,
        "is_active": True,
    },
    {
        "first_name": "Emeka",
        "last_name": "Ugochukwu",
        "email": "student5@atlas.edu",
        "role": UserRole.STUDENT.value,
        "is_active": True,
    },
    {
        "first_name": "Halima",
        "last_name": "Bello",
        "email": "student6@atlas.edu",
        "role": UserRole.STUDENT.value,
        "is_active": True,
    },
    {
        "first_name": "Chisom",
        "last_name": "Okonkwo",
        "email": "student7@atlas.edu",
        "role": UserRole.STUDENT.value,
        "is_active": True,
    },
    {
        "first_name": "Aisha",
        "last_name": "Mohammed",
        "email": "student8@atlas.edu",
        "role": UserRole.STUDENT.value,
        "is_active": True,
    },
    {
        "first_name": "David",
        "last_name": "Oladele",
        "email": "student9@atlas.edu",
        "role": UserRole.STUDENT.value,
        "is_active": True,
    },
]


def seed_users():
    """Insert seed users into the database, skipping any that already exist."""

    created = 0
    skipped = 0

    with get_db_with_ctx_manager() as db:
        for user_data in USERS:
            existing = User.fetch_one_by_field(db, throw_error=False, email=user_data["email"])
            if existing:
                print(f"  [SKIP] {user_data['email']} (already exists)")
                skipped += 1
                continue

            User.create(
                db=db,
                first_name=user_data["first_name"],
                last_name=user_data["last_name"],
                email=user_data["email"],
                password=pwd_context.hash(SEED_PASSWORD),
                role=user_data["role"],
                is_active=user_data["is_active"],
            )
            print(f"  [OK]   {user_data['email']} ({user_data['role']})")
            created += 1

    print(f"\nDone — {created} created, {skipped} skipped.")


if __name__ == "__main__":
    print("=" * 50)
    print("  ATLAS — User Seeder")
    print(f"  Password for all users: {SEED_PASSWORD}")
    print("=" * 50)
    print()

    # Ensure tables exist
    create_database()

    seed_users()

    print()
    print("Login credentials:")
    print("-" * 50)
    print(f"  {'Role':<12} {'Email':<32} Password")
    print("-" * 50)
    print(f"  {'Admin':<12} {'admin@atlas.edu':<32} {SEED_PASSWORD}")
    print(f"  {'Supervisor':<12} {'supervisor1@atlas.edu':<32} {SEED_PASSWORD}")
    print(f"  {'Student':<12} {'student1@atlas.edu':<32} {SEED_PASSWORD}")
    print("-" * 50)
