# AWS RDS PostgreSQL Setup Guide

This guide will help you set up AWS RDS PostgreSQL for storing wildlife sightings data in the cloud.

## 📋 Prerequisites

1. AWS Account with appropriate permissions
2. AWS CLI configured (optional, but helpful)
3. Access to AWS Console: https://console.aws.amazon.com

## 🚀 Step 1: Create RDS PostgreSQL Instance

### Via AWS Console

1. **Navigate to RDS**
   - Go to AWS Console → RDS → Databases
   - Click "Create database"

2. **Database Configuration**
   - **Engine type:** PostgreSQL
   - **Version:** PostgreSQL 15.x or 16.x (recommended)
   - **Template:** Free tier (for development) or Production (for production)
   - **DB instance identifier:** `wildlife-explorer-db`
   - **Master username:** `wildlife_admin` (or your preferred username)
   - **Master password:** Create a strong password (save it securely!)
   - **DB instance class:** `db.t3.micro` (free tier) or `db.t3.small` (for production)

3. **Storage & Connectivity**
   - **Storage:** 20 GB (minimum) - auto-scaling recommended
   - **VPC:** Default VPC or your custom VPC
   - **Public access:** **Yes** (for application access) or **No** (if using VPC peering)
   - **Security group:** Create new or use existing
   - **Database port:** 5432 (default PostgreSQL port)

4. **Database Authentication**
   - **Database authentication:** Password authentication

5. **Additional Configuration**
   - **Initial database name:** `animal_explorer`
   - **Backup retention:** 7 days (recommended)
   - **Enable encryption:** Yes (recommended for production)

6. **Click "Create database"** and wait 5-10 minutes for the instance to be created.

## 🔐 Step 2: Configure Security Group

After RDS instance is created, you need to allow incoming connections:

1. Go to your RDS instance → **Connectivity & security** tab
2. Click on the **Security group** link
3. Click **Edit inbound rules**
4. **Add rule:**
   - **Type:** PostgreSQL
   - **Protocol:** TCP
   - **Port:** 5432
   - **Source:** 
     - For testing: `0.0.0.0/0` (allow from anywhere - **NOT recommended for production**)
     - For production: Your application server's IP or security group
5. Save rules

## 🔗 Step 3: Get Connection Endpoint

1. In RDS Console, select your database instance
2. Under **Connectivity & security**, copy the **Endpoint** (e.g., `wildlife-explorer-db.xxxxx.us-east-2.rds.amazonaws.com`)
3. Note the **Port** (usually 5432)

## ⚙️ Step 4: Configure Application

### Option A: Using Environment Variables (Recommended)

Add to your `.env` file:

```bash
# RDS Configuration
RDS_HOST=your-rds-endpoint.region.rds.amazonaws.com
RDS_PORT=5432
RDS_DATABASE=animal_explorer
RDS_USERNAME=wildlife_admin
RDS_PASSWORD=your_secure_password_here

# Connection Pool Settings (optional)
DB_POOL_SIZE=5
DB_MAX_OVERFLOW=10
DB_POOL_TIMEOUT=30
DB_POOL_RECYCLE=3600
```

### Option B: Using Direct Connection String

Alternatively, you can use a direct connection string:

```bash
DATABASE_URL=postgresql+psycopg2://wildlife_admin:password@your-rds-endpoint.region.rds.amazonaws.com:5432/animal_explorer
```

**Note:** Option A (separate variables) is more secure and easier to manage.

## 🗄️ Step 5: Initialize Database Schema

Run the database initialization script:

```bash
cd backend
python3 init_rds_db.py
```

This will:
- Connect to your RDS instance
- Create all necessary tables
- Optionally seed with sample data

## ✅ Step 6: Test Connection

Test the connection:

```bash
python3 test_rds_connection.py
```

Or use the built-in test:

```bash
python3 -c "from app.database import test_connection; test_connection()"
```

## 📊 Step 7: Verify Setup

1. Check tables were created:
   ```bash
   python3 -c "from app.database import SessionLocal; from app.models import Species, Sighting; db = SessionLocal(); print(f'Species: {db.query(Species).count()}'); print(f'Sightings: {db.query(Sighting).count()}'); db.close()"
   ```

2. Test the API:
   ```bash
   curl http://localhost:8000/health
   ```

## 🔒 Security Best Practices

1. **Never commit credentials to git**
   - Use `.env` file (already in `.gitignore`)
   - Use AWS Secrets Manager for production

2. **Use least privilege access**
   - Create a dedicated database user for the application (not master user)
   - Grant only necessary permissions

3. **Enable SSL/TLS connections** (for production):
   ```python
   # In database.py, add SSL connection args:
   connect_args={
       "sslmode": "require"
   }
   ```

4. **Restrict security group access**
   - Only allow connections from your application servers
   - Use private subnets for production

5. **Enable encryption at rest**
   - Enable during RDS creation
   - Use AWS KMS for key management

## 💰 Cost Considerations

- **Free Tier:** 750 hours/month of `db.t2.micro` or `db.t3.micro` for 12 months
- **Beyond Free Tier:**
  - `db.t3.micro`: ~$15/month
  - `db.t3.small`: ~$30/month
  - Storage: ~$0.10/GB/month
  - Backup storage: ~$0.095/GB/month (first backup size is free)

## 🔄 Migration from SQLite to RDS

If you have existing SQLite data:

1. **Export data from SQLite:**
   ```bash
   python3 export_sqlite_data.py
   ```

2. **Initialize RDS schema:**
   ```bash
   python3 init_rds_db.py
   ```

3. **Import data to RDS:**
   ```bash
   python3 import_to_rds.py
   ```

## 🐛 Troubleshooting

### Connection Timeout
- Check security group allows your IP
- Verify endpoint and port are correct
- Check VPC settings if using private access

### Authentication Failed
- Verify username and password
- Check if database exists
- Ensure user has proper permissions

### Connection Pool Exhausted
- Increase `DB_POOL_SIZE` and `DB_MAX_OVERFLOW`
- Check for connection leaks in code
- Monitor RDS connection metrics

### SSL Errors
- Add `?sslmode=require` to connection string
- Or configure SSL in `connect_args`

## 📚 Additional Resources

- [AWS RDS PostgreSQL Documentation](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html)
- [PostgreSQL Connection Strings](https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-CONNSTRING)
- [SQLAlchemy Connection Pooling](https://docs.sqlalchemy.org/en/20/core/pooling.html)

