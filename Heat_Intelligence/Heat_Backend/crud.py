from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
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
    # Try to find an existing zone very close to the provided coordinates to make seeding idempotent
    lat = zone_data.get("latitude")
    lng = zone_data.get("longitude")
    if lat is not None and lng is not None:
        tol = 0.0005  # roughly ~55m tolerance
        existing = db.query(models.HeatZone).filter(
            models.HeatZone.latitude.between(lat - tol, lat + tol),
            models.HeatZone.longitude.between(lng - tol, lng + tol)
        ).first()
        if existing:
            # update existing record with latest values
            existing.radius = zone_data.get("radius", existing.radius)
            existing.risk_score = zone_data.get("risk_score", existing.risk_score)
            existing.temperature = zone_data.get("temperature", existing.temperature)
            existing.name = zone_data.get("name", existing.name)
            existing.updated_at = datetime.datetime.utcnow()
            db.add(existing)
            db.commit()
            db.refresh(existing)
            return existing

    # No nearby existing zone found — create a new one
    db_zone = models.HeatZone(**zone_data)
    db.add(db_zone)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        # If the zone already exists by id, return that record
        return db.query(models.HeatZone).filter(models.HeatZone.id == zone_data.get("id")).first()
    db.refresh(db_zone)
    return db_zone


def cleanup_duplicate_heat_zones(db: Session, tol: float = 0.0005):
    """Remove duplicate heat zones that are within `tol` degrees of each other.
    Keeps the first-seen record and deletes others.
    """
    zones = db.query(models.HeatZone).order_by(models.HeatZone.updated_at.asc().nullsfirst()).all()
    keep = []
    to_delete_ids = []
    for z in zones:
        found = False
        for k in keep:
            if abs(k.latitude - z.latitude) <= tol and abs(k.longitude - z.longitude) <= tol:
                # duplicate
                to_delete_ids.append(z.id)
                found = True
                break
        if not found:
            keep.append(z)

    if to_delete_ids:
        db.query(models.HeatZone).filter(models.HeatZone.id.in_(to_delete_ids)).delete(synchronize_session=False)
        db.commit()
    return len(to_delete_ids)

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