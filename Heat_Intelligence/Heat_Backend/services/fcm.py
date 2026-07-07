import os
import firebase_admin
from firebase_admin import credentials, messaging

# Initialize Firebase Admin app
def init_firebase():
    if not firebase_admin._apps:
        cred_path = os.environ.get("FIREBASE_CREDENTIALS_PATH", "firebase_credentials.json")
        try:
            if os.path.exists(cred_path):
                cred = credentials.Certificate(cred_path)
                firebase_admin.initialize_app(cred)
                print("Firebase Admin initialized successfully.")
            else:
                print(f"Warning: Firebase credentials not found at {cred_path}. Push notifications will not be sent.")
        except Exception as e:
            print(f"Error initializing Firebase Admin: {e}")

def send_push_notification(token: str, title: str, body: str, data: dict = None):
    """Send a single push notification to a specific token."""
    if not firebase_admin._apps:
        print("Firebase Admin not initialized. Skipping notification.")
        return False

    try:
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data=data if data else {},
            token=token,
        )
        response = messaging.send(message)
        print(f"Successfully sent message: {response}")
        return True
    except Exception as e:
        print(f"Error sending message to {token}: {e}")
        return False

def send_multicast_notification(tokens: list, title: str, body: str, data: dict = None):
    """Send a push notification to multiple tokens."""
    if not firebase_admin._apps:
        print("Firebase Admin not initialized. Skipping multicast notification.")
        return False

    if not tokens:
        return False

    try:
        message = messaging.MulticastMessage(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data=data if data else {},
            tokens=tokens,
        )
        response = messaging.send_multicast(message)
        print(f"{response.success_count} messages were sent successfully")
        if response.failure_count > 0:
            responses = response.responses
            for idx, resp in enumerate(responses):
                if not resp.success:
                    print(f"Failed to send to {tokens[idx]}: {resp.exception}")
        return True
    except Exception as e:
        print(f"Error sending multicast message: {e}")
        return False
