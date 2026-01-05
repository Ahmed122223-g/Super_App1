# Jiwar Backend - 8 Database Architecture

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      API Gateway (FastAPI)                       │
└─────────────────────────────────────────────────────────────────┘
                              │
    ┌─────────┬─────────┬─────┴────┬─────────┬─────────┬──────────┐
    ▼         ▼         ▼          ▼         ▼         ▼          ▼
┌───────┐ ┌───────┐ ┌────────┐ ┌───────┐ ┌────────┐ ┌────────┐ ┌───────┐
│ Users │ │Doctors│ │Pharmaci│ │ Codes │ │Restaur │ │Compani │ │Engines│ ...
│  DB   │ │  DB   │ │ es DB  │ │  DB   │ │ nts DB │ │ es DB  │ │ rs DB │
└───────┘ └───────┘ └────────┘ └───────┘ └────────┘ └────────┘ └───────┘
```

## 🚀 Quick Start

### 1. Setup
```bash
cd backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
```

### 2. Configure .env
```bash
# Copy template and add your database URLs
copy .env.example .env
```

### 3. Run
```bash
python -m uvicorn app.main:app --reload
```

## 🔐 Generate Registration Codes

```bash
cd code_generator
python generate_codes.py
```

**Important:** Codes are stored in `jiwar_codes` database, NOT hardcoded!

## 📡 API
- Swagger: http://localhost:8000/api/docs
- Health: http://localhost:8000/api/health

## 🗄️ 8 Databases

| # | Database | Purpose |
|---|----------|---------|
| 1 | jiwar_users | Authentication & user accounts |
| 2 | jiwar_doctors | Doctor profiles, specialties, ratings |
| 3 | jiwar_pharmacies | Pharmacy profiles, medicines, ratings |
| 4 | jiwar_codes | Registration codes (6 tables) |
| 5 | jiwar_restaurants | Restaurant data (Future) |
| 6 | jiwar_companies | Company data (Future) |
| 7 | jiwar_engineers | Engineer data (Future) |
| 8 | jiwar_mechanics | Mechanic data (Future) |
