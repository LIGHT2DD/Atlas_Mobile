#!/usr/bin/env bash
# ==============================================================================
# ATLAS - Academic Thesis Lifecycle & Assessment Suite
# VIVA DEMO RESET & VERIFICATION SCRIPT (Unix/macOS)
# ==============================================================================
set -e

echo "[ATLAS] Initializing Clean Academic Environment for Presentation & Viva..."
echo "------------------------------------------------------------------------------"

if [ -f ".venv/bin/activate" ]; then
    echo "[*] Activating virtual environment..."
    source .venv/bin/activate
fi

echo "[*] Seeding database with realistic institutional records..."
python -m scripts.seeders.seed_atlas

echo ""
echo "[*] Executing core architectural test suite..."
python -m pytest tests/ -q

echo ""
echo "=============================================================================="
echo "[SUCCESS] ATLAS Environment Ready for Viva Demonstration!"
echo "=============================================================================="
echo "Credentials Reference:"
echo "  Coordinator: coordinator@cstu.edu.bd       Password: Password123"
echo "  Supervisor:  supervisor1@cstu.edu.bd      Password: Password123"
echo "  Supervisor:  supervisor2@cstu.edu.bd      Password: Password123"
echo "  Student:     student1@cstu.edu.bd         Password: Password123"
echo "  Student:     student2@cstu.edu.bd         Password: Password123"
echo "=============================================================================="
