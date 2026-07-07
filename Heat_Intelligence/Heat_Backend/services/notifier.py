from apscheduler.schedulers.asyncio import AsyncIOScheduler
from database import SessionLocal
from .risk import evaluate_heat_risks_and_notify

def scheduled_risk_evaluation():
    db = SessionLocal()
    try:
        evaluate_heat_risks_and_notify(db)
    finally:
        db.close()

class Notifier:
    def __init__(self):
        self.scheduler = AsyncIOScheduler()

    def start(self):
        # Run every 5 minutes
        self.scheduler.add_job(scheduled_risk_evaluation, 'interval', minutes=5)
        self.scheduler.start()
        print("Notifier scheduler started.")

    def shutdown(self):
        self.scheduler.shutdown()
        print("Notifier scheduler shutdown.")

notifier = Notifier()
