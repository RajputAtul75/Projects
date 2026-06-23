from sqlalchemy import Column, String, Float, Boolean, DateTime
from database import Base
import datetime

class HeatZone(Base):
    __tablename__ = "heat_zones"

    id = Column(String, primary_key=True, index=True)
    latitude = Column(Float, index=True)
    longitude = Column(Float, index=True)
    radius = Column(Float)
    risk_score = Column(Float)
    temperature = Column(Float)
    name = Column(String)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow)

class Alert(Base):
    __tablename__ = "alerts"

    id = Column(String, primary_key=True, index=True)
    title = Column(String)
    message = Column(String)
    severity = Column(String)
    risk_score = Column(Float)
    location_name = Column(String)
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)
    is_read = Column(Boolean, default=False)

class HeatHistory(Base):
    __tablename__ = "heat_history"

    id = Column(String, primary_key=True, index=True)
    latitude = Column(Float, index=True)
    longitude = Column(Float, index=True)
    temperature = Column(Float)
    heat_index = Column(Float)
    humidity = Column(Float)
    risk_score = Column(Float)
    location_name = Column(String)
    timestamp = Column(DateTime)
    wind_speed = Column(Float, nullable=True)
    uv_index = Column(Float, nullable=True)

class HeatPrediction(Base):
    __tablename__ = "heat_prediction"

    id = Column(String, primary_key=True, index=True)
    latitude = Column(Float, index=True)
    longitude = Column(Float, index=True)
    temperature = Column(Float)
    heat_index = Column(Float)
    humidity = Column(Float)
    risk_score = Column(Float)
    location_name = Column(String)
    timestamp = Column(DateTime)
    wind_speed = Column(Float, nullable=True)
    uv_index = Column(Float, nullable=True)

class UserDevice(Base):
    __tablename__ = "user_devices"

    id = Column(String, primary_key=True, index=True)
    user_id = Column(String, nullable=True, index=True)
    fcm_token = Column(String, unique=True, index=True)
    latitude = Column(Float)
    longitude = Column(Float)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)