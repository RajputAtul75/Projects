from sqlalchemy.orm import Session
import models
import uuid
import datetime

def get_heat_zones(db: Session, lat: float, lng: float, radius: float):
    # In a real app, use PostGIS. For now, simple box bound approximation
    # 1 degree of lat ~ 111km
    deg_radius = radius / 111000.0
    return db.query(models.HeatZone).filter(
        models.HeatZone.latitude.between(lat - deg_radius, lat + deg_radius),
        models.HeatZone.longitude.between(lng - deg_radius, lng + deg_radius)
    ).all()

def create_heat_zone(db: Session, zone_data: dict):
    db_zone = models.HeatZone(**zone_data)
    db.add(db_zone)
    db.commit()
    db.refresh(db_zone)
    return db_zone

def get_alerts(db: Session):
    return db.query(models.Alert).order_by(models.Alert.timestamp.desc()).all()

def create_alert(db: Session, alert_data: dict):
    db_alert = models.Alert(**alert_data)
    db.add(db_alert)
    db.commit()
    db.refresh(db_alert)
    return db_alert

def get_heat_history(db: Session, lat: float, lng: float):
    deg_radius = 0.05
    return db.query(models.HeatHistory).filter(
        models.HeatHistory.latitude.between(lat - deg_radius, lat + deg_radius),
        models.HeatHistory.longitude.between(lng - deg_radius, lng + deg_radius)
    ).order_by(models.HeatHistory.timestamp.asc()).all()

def create_heat_history(db: Session, data: dict):
    db_history = models.HeatHistory(**data)
    db.add(db_history)
    db.commit()
    db.refresh(db_history)
    return db_history

def get_heat_predictions(db: Session, lat: float, lng: float):
    deg_radius = 0.05
    return db.query(models.HeatPrediction).filter(
        models.HeatPrediction.latitude.between(lat - deg_radius, lat + deg_radius),
        models.HeatPrediction.longitude.between(lng - deg_radius, lng + deg_radius),
        models.HeatPrediction.timestamp >= datetime.datetime.utcnow()
    ).order_by(models.HeatPrediction.timestamp.asc()).all()

def create_heat_prediction(db: Session, data: dict):
    db_pred = models.HeatPrediction(**data)
    db.add(db_pred)
    db.commit()
    db.refresh(db_pred)
    return db_pred