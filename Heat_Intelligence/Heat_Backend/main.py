from datetime import datetime, timedelta
import random
from typing import Optional, List

from fastapi import FastAPI, Query
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="Heat Intelligence API", version="1.0.0")

# Enable CORS for frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
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


# --- Endpoints ---

@app.get("/api/heat-risk", response_model=HeatData)
async def get_heat_risk(lat: float = Query(...), lng: float = Query(...)):
    """Returns the real-time heat risk data for a given location."""
    # Generating realistic looking response data
    temp = random.uniform(35.0, 42.0)
    risk = random.uniform(0.3, 0.9)
    return HeatData(
        latitude=lat,
        longitude=lng,
        temperature=round(temp, 1),
        heat_index=round(temp + random.uniform(2.0, 5.0), 1),
        humidity=round(random.uniform(40.0, 75.0), 1),
        risk_score=round(risk, 2),
        location_name=f"Lat {round(lat, 2)}, Lng {round(lng, 2)}",
        timestamp=datetime.now().isoformat(),
        wind_speed=round(random.uniform(5.0, 15.0), 1),
        uv_index=round(random.uniform(6.0, 11.0), 1),
    )

@app.get("/api/heat-zones", response_model=List[HeatZone])
async def get_heat_zones(lat: float = Query(...), lng: float = Query(...), radius: float = Query(10.0)):
    """Returns a list of high-risk heat zones near the center coordinates."""
    zones = []
    
    # Generate some dummy zones around the point
    for i in range(5):
        lat_offset = random.uniform(-0.02, 0.02)
        lng_offset = random.uniform(-0.02, 0.02)
        risk = random.uniform(0.4, 0.9)
        
        zones.append(HeatZone(
            id=f"zone_{i+1}",
            latitude=round(lat + lat_offset, 5),
            longitude=round(lng + lng_offset, 5),
            radius=round(random.uniform(300.0, 800.0), 1),
            risk_score=round(risk, 2),
            temperature=round(35.0 + (risk * 10), 1),
            name=f"Zone {'ABCDE'[i]}",
            updated_at=datetime.now().isoformat()
        ))
    return zones

@app.get("/api/heat-history", response_model=List[HeatData])
async def get_heat_history(lat: float = Query(...), lng: float = Query(...)):
    """Returns 7-day historical heat data."""
    history = []
    now = datetime.now()
    for i in range(7):
        temp = random.uniform(34.0, 40.0)
        history.append(HeatData(
            latitude=lat,
            longitude=lng,
            temperature=round(temp, 1),
            heat_index=round(temp + random.uniform(2.0, 4.0), 1),
            humidity=round(random.uniform(50.0, 70.0), 1),
            risk_score=round(random.uniform(0.3, 0.8), 2),
            location_name=f"Location",
            timestamp=(now - timedelta(days=6 - i)).isoformat(),
            wind_speed=round(random.uniform(5.0, 12.0), 1),
            uv_index=round(random.uniform(5.0, 9.0), 1),
        ))
    return history

@app.get("/api/heat-prediction", response_model=List[HeatData])
async def get_heat_prediction(lat: float = Query(...), lng: float = Query(...)):
    """Returns 24-hour heat wave prediction (8 periods of 3 hrs)."""
    prediction = []
    now = datetime.now()
    for i in range(8):
        temp = random.uniform(36.0, 42.0)
        prediction.append(HeatData(
            latitude=lat,
            longitude=lng,
            temperature=round(temp, 1),
            heat_index=round(temp + random.uniform(3.0, 5.0), 1),
            humidity=round(random.uniform(45.0, 65.0), 1),
            risk_score=round(random.uniform(0.4, 0.9), 2),
            location_name=f"Location Prediction",
            timestamp=(now + timedelta(hours=(i + 1) * 3)).isoformat(),
            wind_speed=round(random.uniform(4.0, 10.0), 1),
            uv_index=round(random.uniform(6.0, 11.0), 1),
        ))
    return prediction

@app.get("/api/alerts", response_model=List[AlertModel])
async def get_alerts():
    """Returns active heat alerts."""
    return [
        AlertModel(
            id="1",
            title="Extreme Heat Warning",
            message="Temperature in Industrial Zone A has reached 42.3C. Risk score: 0.85.",
            severity="high",
            risk_score=0.85,
            location_name="Industrial Zone A",
            timestamp=datetime.now().isoformat(),
            is_read=False
        ),
        AlertModel(
            id="2",
            title="Moderate Heat Advisory",
            message="Market District is experiencing elevated temperatures. Stay hydrated.",
            severity="moderate",
            risk_score=0.62,
            location_name="Market District",
            timestamp=(datetime.now() - timedelta(hours=1)).isoformat(),
            is_read=False
        )
    ]