from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
import uuid
import jwt
import smtplib
from pydantic import ValidationError
from fastapi import HTTPException, status
from passlib.context import CryptContext
from fastapi import FastAPI, HTTPException, Depends
from app.core.security import get_password, verify_password
import pymongo
import json
import random
from urllib.parse import urlencode
from app.core.config import logger_settings, Settings
logger = logger_settings.get_logger(__name__)
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
from app.core.security import create_access_token

class UserService:
    @staticmethod
    async def send_email(email: str, reset_link):
        try:
            # Email details
            sender_email = logger_settings.MY_EMAIL
            receiver_email = email
            subject = "PASSWORD RESET LINK REQUEST: Jumper Media"
            body = f"Password Reset Link:\n{reset_link}"

            # Create the email message
            message = MIMEMultipart()
            message["From"] = sender_email
            message["To"] = receiver_email
            message["Subject"] = subject
            message.attach(MIMEText(body, "plain"))
            # Convert the message to a string
            email_string = message.as_string()

            server = smtplib.SMTP("smtp.gmail.com", 587)
            server.starttls()
            server.login(logger_settings.MY_EMAIL, logger_settings.EMAIL_APP_PASSWORD)
            server.sendmail(logger_settings.MY_EMAIL, email, email_string)
            return True
        except Exception as e:
            logger.error(f"Error: {e}")
            return False
        finally:
            server.quit()
