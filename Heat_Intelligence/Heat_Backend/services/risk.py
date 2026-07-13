import uuid
from datetime import datetime, timedelta
from sqlalchemy.orm import Session
import crud
import models
from .fcm import send_push_notification

def evaluate_heat_risks_and_notify(db: Session):
    """
    Evaluates current and predicted high risk heat zones and notifies users who are nearby.
    """
    # 1. Find all registered devices (Do this first so we can use it for both)
    devices = crud.get_all_devices(db)
    if not devices:
        return

    # 2. Evaluate CURRENT high risk heat zones
    critical_zones = db.query(models.HeatZone).filter(models.HeatZone.risk_score > 0.8).all()
    
    for zone in critical_zones:
        # Check if an alert already exists for this zone recently to avoid spam
        recent_alert = db.query(models.Alert).filter(
            models.Alert.location_name == zone.name,
            models.Alert.title == "Automated Extreme Heat Warning",
            models.Alert.timestamp >= datetime.utcnow() - timedelta(hours=1)
        ).first()
        
        if not recent_alert:
            # Create a new alert in DB
            alert = crud.create_alert(db, {
                "id": str(uuid.uuid4()),
                "title": "Automated Extreme Heat Warning",
                "message": f"Critical heat level detected in {zone.name}. Temperature at {zone.temperature}°C.",
                "severity": "high",
                "risk_score": zone.risk_score,
                "location_name": zone.name
            })
            print(f"Generated new alert for {zone.name}")

            # Notify users near this zone
            for device in devices:
                if device.latitude is None or device.longitude is None:
                    continue
                
                # Simple bounding box approximation for nearby check (e.g., within ~10-15km)
                # 0.1 degree is roughly 11km
                lat_diff = abs(device.latitude - zone.latitude)
                lng_diff = abs(device.longitude - zone.longitude)
                
                if lat_diff < 0.15 and lng_diff < 0.15:
                    print(f"Notifying device {device.id} about {zone.name}")
                    send_push_notification(
                        token=device.fcm_token,
                        title=alert.title,
                        body=alert.message,
                        data={
                            "type": "heat_alert",
                            "zone_id": zone.id,
                            "alert_id": alert.id,
                            "risk_score": str(zone.risk_score)
                        }
                    )

    # 3. Evaluate PREDICTED heat waves (Future)
    # Look for high risk predictions that are at least 2 hours in the future
    future_time = datetime.utcnow() + timedelta(hours=2)
    predictions = db.query(models.HeatPrediction).filter(
        models.HeatPrediction.risk_score > 0.8,
        models.HeatPrediction.timestamp >= future_time
    ).all()

    for pred in predictions:
        # Avoid spamming predictive alerts for the same location within 12 hours
        recent_pred_alert = db.query(models.Alert).filter(
            models.Alert.location_name == pred.location_name,
            models.Alert.title == "Predictive Heat Warning",
            models.Alert.timestamp >= datetime.utcnow() - timedelta(hours=12)
        ).first()
        
        if not recent_pred_alert:
            time_str = pred.timestamp.strftime("%I:%M %p")
            alert = crud.create_alert(db, {
                "id": str(uuid.uuid4()),
                "title": "Predictive Heat Warning",
                "message": f"⚠️ Severe heatwave predicted to hit your area at {time_str}. Temperature will reach {pred.temperature}°C. Please take precautions.",
                "severity": "high",
                "risk_score": pred.risk_score,
                "location_name": pred.location_name
            })
            print(f"Generated new predictive alert for {pred.location_name} at {time_str}")

            # Notify users near this predicted zone
            for device in devices:
                if device.latitude is None or device.longitude is None:
                    continue
                
                lat_diff = abs(device.latitude - pred.latitude)
                lng_diff = abs(device.longitude - pred.longitude)
                
                if lat_diff < 0.15 and lng_diff < 0.15:
                    print(f"Notifying device {device.id} about future heat in {pred.location_name}")
                    send_push_notification(
                        token=device.fcm_token,
                        title=alert.title,
                        body=alert.message,
                        data={
                            "type": "heat_prediction_alert",
                            "alert_id": alert.id,
                            "risk_score": str(pred.risk_score)
                        }
                    )
