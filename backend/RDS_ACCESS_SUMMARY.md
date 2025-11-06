# RDS Database Access Summary

## 🔗 How We Connect to RDS

### Current Configuration
The application connects to AWS RDS PostgreSQL using **hardcoded credentials** in `app/config.py`. The connection is established automatically when the application starts.

### Connection Details
- **Host:** `wildlife-explorer-db.cda2ce0kia2k.us-east-2.rds.amazonaws.com`
- **Port:** `5432`
- **Database:** `animal_explorer`
- **Username:** `wildlife_admin`
- **Password:** `wowCym-5cinpy-mywbud`
- **SSL:** Required (`sslmode=require`)

### Connection Method
The connection is built in `app/config.py` → `get_database_url()` method, which constructs a PostgreSQL connection string:
```
postgresql+psycopg2://wildlife_admin:wowCym-5cinpy-mywbud@wildlife-explorer-db.cda2ce0kia2k.us-east-2.rds.amazonaws.com:5432/animal_explorer
```

### SSL Configuration
SSL encryption is required for RDS connections. This is configured in `app/database.py` with:
```python
connect_args={
    "sslmode": "require"
}
```

---

## 🖥️ Accessing RDS via AWS Console

### Can You Modify/Access RDS in the Console?

**Yes, you can access and manage RDS through the AWS Console**, but with limitations:

### What You CAN Do via AWS Console:

1. **View RDS Instance Details**
   - Go to: https://console.aws.amazon.com/rds
   - Sign in with Account ID: `339712839005`
   - Navigate to: RDS → Databases → `wildlife-explorer-db`
   - View: Status, configuration, metrics, logs

2. **Modify RDS Settings**
   - Click "Modify" on the RDS instance
   - Can change: Instance class, storage, backup settings, security groups
   - **Note:** Changes require a restart and may cause downtime

3. **Reset Database Password**
   - Go to RDS instance → Modify
   - Under "Master password" → Click "Change password"
   - Enter new password and save
   - **Important:** This will require updating the password in `app/config.py`

4. **View Security Groups**
   - Check connectivity & security settings
   - Modify inbound/outbound rules
   - Add your IP address if connection is blocked

5. **View Database Logs**
   - Check error logs, slow query logs
   - Monitor database performance

6. **Create Database Snapshots**
   - Create manual backups
   - Restore from snapshots if needed

### What You CANNOT Do via AWS Console:

1. **Direct Database Access (SQL Queries)**
   - AWS Console doesn't provide a SQL query interface
   - You need external tools for this (see below)

2. **Browse Tables/Data Directly**
   - Console shows instance info, not database contents
   - Use database tools instead (pgAdmin, DBeaver, psql)

3. **Run SQL Commands**
   - Console is for infrastructure management
   - Use application code or database clients for SQL

---

## 🛠️ Tools for Database Access

### Option 1: Application Code (Python)
```python
from app.database import SessionLocal
from app.models import Sighting

db = SessionLocal()
sightings = db.query(Sighting).all()
db.close()
```

### Option 2: Command Line (psql)
```bash
psql -h wildlife-explorer-db.cda2ce0kia2k.us-east-2.rds.amazonaws.com \
     -p 5432 \
     -U wildlife_admin \
     -d animal_explorer \
     -W
# Enter password when prompted: wowCym-5cinpy-mywbud
```

### Option 3: GUI Tools

**pgAdmin:**
- Download: https://www.pgadmin.org/
- Connection settings:
  - Host: `wildlife-explorer-db.cda2ce0kia2k.us-east-2.rds.amazonaws.com`
  - Port: `5432`
  - Database: `animal_explorer`
  - Username: `wildlife_admin`
  - Password: `wowCym-5cinpy-mywbud`
  - SSL Mode: Require

**DBeaver:**
- Download: https://dbeaver.io/
- Same connection settings as pgAdmin
- Driver: PostgreSQL

---

## 📝 Making Changes to RDS Data

### Via Application Scripts
```bash
# Remove sightings without media
python3 remove_sightings_without_media.py --auto-confirm

# Initialize database
python3 init_rds_db.py --seed

# Test connection
python3 test_rds_connection.py
```

### Via Direct SQL (psql)
```bash
psql -h wildlife-explorer-db.cda2ce0kia2k.us-east-2.rds.amazonaws.com \
     -p 5432 \
     -U wildlife_admin \
     -d animal_explorer

# Then run SQL commands:
SELECT * FROM sightings;
DELETE FROM sightings WHERE media_url IS NULL AND audio_url IS NULL;
```

### Via Python Scripts
```python
from app.database import SessionLocal
from app.models import Sighting
from sqlalchemy import and_

db = SessionLocal()
# Delete sightings without media
db.query(Sighting).filter(
    and_(
        Sighting.media_url.is_(None),
        Sighting.audio_url.is_(None)
    )
).delete()
db.commit()
db.close()
```

---

## 🔒 Security Notes

1. **Credentials are hardcoded** in `app/config.py` - this is for development convenience
2. **For production**, consider using:
   - AWS Secrets Manager
   - Environment variables (but .env file is gitignored)
   - IAM database authentication (more secure)

3. **SSL is required** - all connections are encrypted

4. **Security Group** must allow your IP address (currently configured for access)

---

## ✅ Verification

To verify RDS connection is working:
```bash
cd backend
python3 test_rds_connection.py
```

Expected output:
```
✅ Connection successful!
📊 Database Status:
   Species table: 6 records
   Sightings table: 2 records
```

---

## 📚 Related Files

- `app/config.py` - RDS connection configuration
- `app/database.py` - Database engine setup with SSL
- `RDS_CONNECTION_GUIDE.md` - Detailed connection guide
- `remove_sightings_without_media.py` - Example script for database operations

