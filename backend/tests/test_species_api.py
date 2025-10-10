# tests/test_species_api.py
import os
os.environ.setdefault("DATABASE_URL", "sqlite:///./test_species_api.db")
import sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.main import app
from app.database import get_db
from app.models import Base, Species as SpeciesModel

# 1) 用文件型 SQLite（避免 :memory: 的多连接问题）
TEST_DB_URL = "sqlite:///./test_species_api.db"
engine = create_engine(TEST_DB_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)

# 2) 建表并插入一条假数据：id='0100', scientific_name='squirrel'
def _seed():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    with TestingSessionLocal() as s:
        s.add(SpeciesModel(id="0100", scientific_name="squirrel"))
        s.commit()

_seed()

# 3) 覆盖 app 的 get_db 依赖，让路由使用我们的临时库
def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db

client = TestClient(app)

def test_get_species_squirrel():
    # 如果你的 router 是 include 到 prefix="/v1/species"，就这么写：
    resp = client.get("/v1/species/0100")
    # 如果没有统一前缀，且你的装饰器是 @router.get("/{species_id}")，就改为：
    # resp = client.get("/species/0100")  # 按你的真实挂载路径来

    print("status:", resp.status_code)
    print("json:", resp.json())
    assert resp.status_code == 200

    body = resp.json()
    assert body["species"] == "squirrel"      # 来自 DB
    # 因为是拼错的学名，Wikipedia 大概率查不到，你的实现会返回 None（符合你要“暴露问题”）
    assert body["english_name"] is None or isinstance(body["english_name"], str)
    assert body["description"]  # 有摘要
