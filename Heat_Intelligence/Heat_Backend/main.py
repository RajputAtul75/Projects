from datetime import datetime, timedelta
import collections
from typing import Optional, List
import asyncio
import time

from fastapi import FastAPI, Query, Depends, HTTPException
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
import httpx

import models, crud
from database import engine, SessionLocal, Base
from sqlalchemy.orm import Session

from apscheduler.schedulers.asyncio import AsyncIOScheduler
import uuid

from services.fcm import init_firebase, send_push_notification
from services.notifier import notifier

def check_heat_alerts():
    """Background task to scan heat zones and generate alerts if risk gets too high."""
    db = SessionLocal()
    try:
        # Example logic: scan all zones with risk > 0.8 that haven't been alerted
        zones = db.query(models.HeatZone).filter(models.HeatZone.risk_score > 0.8).all()
        for zone in zones:
            # Check if an alert already exists for this zone recently (mock simplifcation)
            recent_alert = db.query(models.Alert).filter(
                models.Alert.location_name == zone.name,
                models.Alert.timestamp >= datetime.now() - timedelta(hours=1)
            ).first()
            
            if not recent_alert:
                crud.create_alert(db, {
                    "id": str(uuid.uuid4()),
                    "title": "Automated Extreme Heat Warning",
                    "message": f"Critical heat level detected in {zone.name}. Temperature at {zone.temperature}C.",
                    "severity": "high",
                    "risk_score": zone.risk_score,
                    "location_name": zone.name
                })
                print(f"Generated alert for {zone.name}")
    finally:
        db.close()

from contextlib import asynccontextmanager

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Ensure DB tables exist
    Base.metadata.create_all(bind=engine)

    init_firebase()
    notifier.start()
    
    # Clean up any accidental duplicate seeded zones from previous runs
    db = SessionLocal()
    try:
        try:
            removed = crud.cleanup_duplicate_heat_zones(db)
            if removed:
                print(f"Cleaned up {removed} duplicate heat zone(s) on startup")
        except Exception as e:
            print("Warning: failed to cleanup duplicate zones:", e)
    finally:
        db.close()
        
    yield

    # Graceful shutdown
    notifier.shutdown()

app = FastAPI(title="Heat Intelligence API", version="1.0.0", lifespan=lifespan)

if __name__ == "__main__":
    import uvicorn
    import os
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run("main:app", host="0.0.0.0", port=port)


# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Enable CORS for frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


# --- Pydantic Models ---

class HeatData(BaseModel):
    latitude: float
    longitude: float
    temperature: float
    heat_index: float
    humidity: float
    risk_score: float
    location_name: str
    timestamp: str
    wind_speed: Optional[float] = None
    uv_index: Optional[float] = None

class HeatZone(BaseModel):
    id: str
    latitude: float
    longitude: float
    radius: float
    risk_score: float
    temperature: float
    name: str
    updated_at: str

class AlertModel(BaseModel):
    id: str
    title: str
    message: str
    severity: str
    risk_score: float
    location_name: str
    timestamp: str
    is_read: bool = False

class DeviceRegistration(BaseModel):
    fcm_token: str
    latitude: float
    longitude: float


# --- Endpoints ---

OPEN_METEO_BASE_URL = "https://api.open-meteo.com/v1/forecast"

# Simple in-memory cache to avoid IP rate limits from open-meteo
weather_cache = {}

async def fetch_open_meteo_current(lat: float, lng: float):
    # Cache key based on roughly 11km grid
    key = f"{round(lat, 1)}_{round(lng, 1)}"
    now = time.time()
    
    if key in weather_cache:
        cached_data, timestamp = weather_cache[key]
        if now - timestamp < 300: # 5 minutes TTL
            return cached_data

    # Add basic retry logic and timeout to make external calls more robust
    params = {
        "latitude": lat,
        "longitude": lng,
        "current": "temperature_2m,relative_humidity_2m,wind_speed_10m",
        "timezone": "auto"
    }

    retries = 3
    timeout = httpx.Timeout(10.0)
    async with httpx.AsyncClient(timeout=timeout) as client:
        for attempt in range(1, retries + 1):
            try:
                res = None
                res = await client.get(OPEN_METEO_BASE_URL, params=params)
                res.raise_for_status()
                data = res.json()
                weather_cache[key] = (data, now)
                return data
            except (httpx.RequestError, httpx.HTTPStatusError) as e:
                # If we encounter 429 and have cached data, return the stale cache
                if res is not None and res.status_code == 429 and key in weather_cache:
                    return weather_cache[key][0]
                if attempt == retries:
                    # Provide fallback offline data on 429 to avoid crashing
                    if isinstance(e, httpx.HTTPStatusError) and e.response.status_code == 429:
                        fallback_data = {
                            "current": {
                                "temperature_2m": 35.0,
                                "relative_humidity_2m": 50.0,
                                "wind_speed_10m": 10.0
                            }
                        }
                        weather_cache[key] = (fallback_data, now)
                        return fallback_data
                    raise
                await asyncio.sleep(0.5 * attempt)

def calculate_risk(temp: float, humidity: float):
    # Basic Heat Risk logic (ML substitute)
    # Higher temp and humidity -> higher risk
    base_risk = (temp - 30) / 15.0 # normalize somewhat
    humid_factor = (humidity - 40) / 100.0
    risk = base_risk + humid_factor
    return max(0.0, min(risk, 1.0))

@app.get("/api/heat-risk", response_model=HeatData)
async def get_heat_risk(lat: float = Query(...), lng: float = Query(...)):
    """Returns the real-time heat risk data from Open-Meteo with calculated risk score."""
    try:
        data = await fetch_open_meteo_current(lat, lng)
        current = data.get("current", {})
        temp = current.get("temperature_2m", 35.0)
        humidity = current.get("relative_humidity_2m", 50.0)
        wind_speed = current.get("wind_speed_10m")
        
        # Calculate derived metrics
        heat_index = temp + (humidity * 0.05) # dummy calculation
        risk_score = calculate_risk(temp, humidity)
        
        return HeatData(
            latitude=lat,
            longitude=lng,
            temperature=temp,
            heat_index=round(heat_index, 1),
            humidity=humidity,
            risk_score=round(risk_score, 2),
            location_name=f"Lat {round(lat, 2)}, Lng {round(lng, 2)}",
            timestamp=datetime.now().isoformat(),
            wind_speed=wind_speed,
            uv_index=None,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/heat-zones", response_model=List[HeatZone])
async def get_heat_zones(lat: float = Query(...), lng: float = Query(...), radius: float = Query(10.0), db: Session = Depends(get_db)):
    """Returns a list of high-risk heat zones from the database."""
    zones = crud.get_heat_zones(db, lat, lng, radius)
    if not zones:
        # Seed some dummy zones close to requested coordinate for testing
        crud.create_heat_zone(db, {
            "id": str(uuid.uuid4()), "latitude": lat + 0.01, "longitude": lng + 0.01,
            "radius": 500, "risk_score": 0.8, "temperature": 39.5, "name": "Industrial Area"
        })
        crud.create_heat_zone(db, {
            "id": str(uuid.uuid4()), "latitude": lat - 0.01, "longitude": lng - 0.01,
            "radius": 800, "risk_score": 0.6, "temperature": 36.0, "name": "Downtown Strip"
        })
        zones = crud.get_heat_zones(db, lat, lng, radius)

    return [
        HeatZone(
            id=z.id,
            latitude=z.latitude,
            longitude=z.longitude,
            radius=z.radius,
            risk_score=z.risk_score,
            temperature=z.temperature,
            name=z.name,
            updated_at=z.updated_at.isoformat() if z.updated_at else datetime.now().isoformat(),
        )
        for z in zones
    ]

@app.get("/api/heat-history", response_model=List[HeatData])
async def get_heat_history(lat: float = Query(...), lng: float = Query(...), db: Session = Depends(get_db)):
    """Returns 7-day historical heat data from database."""
    history = crud.get_heat_history(db, lat, lng)
    if not history:
        # Seed test history
        now = datetime.now()
        for i in range(7):
            crud.create_heat_history(db, {
                "id": str(uuid.uuid4()), "latitude": lat, "longitude": lng,
                "temperature": 34.0 + i, "heat_index": 36.0 + i, "humidity": 55.0, 
                "risk_score": 0.4 + (i*0.05), "location_name": "Location",
                "timestamp": now - timedelta(days=6 - i)
            })
        history = crud.get_heat_history(db, lat, lng)
    
    # Map to pydantic model format (which expects timestamp as str by default since we defined it as str in model but db is datetime)
    return [
        HeatData(
            latitude=h.latitude, longitude=h.longitude, temperature=h.temperature,
            heat_index=h.heat_index, humidity=h.humidity, risk_score=h.risk_score,
            location_name=h.location_name, timestamp=h.timestamp.isoformat(),
            wind_speed=h.wind_speed, uv_index=h.uv_index
        ) for h in history
    ]

@app.get("/api/heat-prediction", response_model=List[HeatData])
async def get_heat_prediction(lat: float = Query(...), lng: float = Query(...), db: Session = Depends(get_db)):
    """Returns 24-hour heat wave prediction from database."""
    predictions = crud.get_heat_predictions(db, lat, lng)
    if not predictions:
        now = datetime.now()
        for i in range(8):
            crud.create_heat_prediction(db, {
                "id": str(uuid.uuid4()), "latitude": lat, "longitude": lng,
                "temperature": 36.0 + (i*0.5), "heat_index": 38.0 + (i*0.6), "humidity": 50.0,
                "risk_score": 0.5 + (i*0.04), "location_name": "Predicted Location",
                "timestamp": now + timedelta(hours=(i + 1) * 3)
            })
        predictions = crud.get_heat_predictions(db, lat, lng)
    
    return [
        HeatData(
            latitude=p.latitude, longitude=p.longitude, temperature=p.temperature,
            heat_index=p.heat_index, humidity=p.humidity, risk_score=p.risk_score,
            location_name=p.location_name, timestamp=p.timestamp.isoformat(),
            wind_speed=p.wind_speed, uv_index=p.uv_index
        ) for p in predictions
    ]

@app.get("/api/alerts", response_model=List[AlertModel])
async def get_alerts_endpoint(db: Session = Depends(get_db)):
    """Returns active heat alerts from the database."""
    alerts = crud.get_alerts(db)
    if not alerts:
        # Seed test alerts
        crud.create_alert(db, {
            "id": "test_alert_A", "title": "Extreme Heat Warning",
            "message": "Temperature is critically high in Industrial Zone.",
            "severity": "high", "risk_score": 0.85, "location_name": "Industrial Zone"
        })
        alerts = crud.get_alerts(db)
    return alerts

@app.post("/api/notifications/register")
async def register_device(registration: DeviceRegistration, db: Session = Depends(get_db)):
    """Registers a device's FCM token and its location."""
    crud.upsert_device(db, registration.fcm_token, registration.latitude, registration.longitude)
    return {"status": "success", "message": "Device registered"}

@app.post("/api/notifications/debug-trigger")
async def debug_trigger_notification(db: Session = Depends(get_db)):
    """Manually triggers the risk evaluation and notification process for testing."""
    from services.risk import evaluate_heat_risks_and_notify
    evaluate_heat_risks_and_notify(db)
    return {"status": "success", "message": "Triggered risk evaluation"}


@app.get("/", include_in_schema=False)
async def root():
    return {"status": "ok", "service": "Heat Intelligence API", "version": "1.0.0"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)