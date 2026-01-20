from fastapi import APIRouter, Depends, HTTPException, status, Body
from fastapi.responses import JSONResponse
from fastapi.security import OAuth2PasswordRequestForm, OAuth2PasswordBearer
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.ext.asyncio import AsyncSession
import aiomysql
import asyncpg
from jose import jwt, JWTError
from pydantic import BaseModel, EmailStr, ValidationError
from sqlalchemy.exc import IntegrityError
from sqlalchemy import or_
from typing import Optional, Union, Any
from app.core.config import logger_settings
logger = logger_settings.get_logger(__name__)
from app.schemas.client_schema import (UserOut,
                                       RegisterSchema, 
                                       TokenSchema, 
                                       TokenPayload, 
                                       PasswordResetRequest, 
                                       PasswordResetConfirm)
from app.models.user_model import User
from app.services.auth_service import AuthDatabaseService
from app.api.deps.user_deps import get_current_user, reuseable_oauth
from app.core.security import (get_password, 
                               verify_password, 
                               create_refresh_token, 
                               decode_jwt_token, 
                               create_access_token)
from app.services.user_service import UserService
from sqlalchemy.future import select

auth_router = APIRouter()

########################################
##.           login endpoint
########################################

@auth_router.post("/login", response_model=TokenSchema)
async def login(form_data: OAuth2PasswordRequestForm = Depends(), db: asyncpg.Connection = Depends(AuthDatabaseService.get_db)):
    try:
        # Fetch the user by email
        query = "SELECT * FROM auth.auth_users WHERE email = $1"
        user = await db.fetchrow(query, form_data.username)

        # Convert Record → dict (like DictCursor)
        # user = dict(user_record) if user_record else None
        
        if not user or (not await verify_password(form_data.password, user['password'])):
            logger.error("Invalid credentials provided for login.")
            raise HTTPException(status_code=400, detail="Invalid credentials")
        
        # if not user:
        #     raise HTTPException(status_code=400, detail="Invalid credentials")

        # Return tokens if credentials are correct
        return {
            "access_token": await create_access_token(subject=user['id']),
            "refresh_token": await create_refresh_token(subject=user['id'])
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"An error occurred: {e}")
    
########################################
##.         register endpoint
########################################

@auth_router.post("/register", response_model=dict)
async def register(user: RegisterSchema, db: asyncpg.Connection = Depends(AuthDatabaseService.get_db)):
    try:
        # Check if the user already exists by email or username
        query_check = """
            SELECT * FROM auth.auth_users 
            WHERE email = $1 OR username = $2
        """
        user_exists = await db.fetchrow(query_check, user.email, user.username)
        # user_exists = dict(user_exists_record) if user_exists_record else None
        
        if user_exists:
            raise HTTPException(status_code=400, detail="User already exists")

        # Hash the password
        hashed_password = await get_password(user.password)
        
        # Insert new user
        query_insert = """
            INSERT INTO auth.auth_users 
            (username, email, password, phone_number, address, security_question, security_answer)
            VALUES ($1, $2, $3, $4, $5, $6, $7)
        """
        
        await db.execute(
            query_insert,
            user.username,
            user.email,
            hashed_password,
            user.phone_number,
            user.address,
            user.security_question,
            user.security_answer
        )

        return {"message": "User registered successfully"}

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"An error occurred: {e}")
        
########################################
##.          refresh endpoint
########################################

@auth_router.post("/refresh", response_model=TokenSchema)
async def refresh_token(refresh_token: str = Body(...), db: asyncpg.Connection = Depends(AuthDatabaseService.get_db)):
    try:
        # Decode the JWT to get the token data
        token_data = await decode_jwt_token(refresh_token)
        
        # Fetch the user from Postgres based on the ID in the token
        query = "SELECT * FROM auth.auth_users WHERE id = $1"
        user = await db.fetchrow(query, token_data.sub)
        
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        
        return {
            "access_token": await create_access_token(subject=user["id"]),
            "refresh_token": await create_refresh_token(subject=user["id"])
        }

    except Exception as e:
        logger.error(f"An unexpected error occurred during token refresh. Error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="An unexpected error occurred during token refresh"
        )

########################################
##.        reset-email endpoint
########################################

@auth_router.post('/reset/email', summary="Send email for password reset", response_model=PasswordResetRequest)
async def reset_password_email(request: PasswordResetRequest, db: asyncpg.Connection = Depends(AuthDatabaseService.get_db)):
    try:
        # Fetch the user by email from Postgres
        query = "SELECT * FROM auth.auth_users WHERE email = $1"
        user = await db.fetchrow(query, request.email)

        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        
        # Generate a reset token
        reset_token = await create_access_token(subject=user["email"])
        reset_link = f"{logger_settings.FRONTEND_API_URL}/reset/password?token={reset_token}"

        # Send the reset email
        _status = await UserService.send_email(user["email"], reset_link)

        if _status:
            logger.debug("Password reset email sent!")
        else:
            logger.debug("Password reset email not sent!")

        return JSONResponse(
            content={"message": "Reset email sent successfully!"}
        )

    except Exception as e:
        logger.error(f"Error sending reset email: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="An error occurred while processing your request"
        )
    
    finally:
        db.close()

########################################
##.      reset password endpoint
########################################

@auth_router.post("/reset/password", summary="Reset password")
async def reset_password_confirm(request: PasswordResetConfirm, db: asyncpg.Connection = Depends(AuthDatabaseService.get_db)):
    try:
        # Decode the reset token
        payload = jwt.decode(request.token, logger_settings.JWT_SECRET_KEY, algorithms=[logger_settings.ALGORITHM])
        email = payload.get("sub")
        
        if email is None:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid token")
        
        # Fetch user by email from Postgres
        user = await db.fetchrow("SELECT * FROM auth.auth_users WHERE email = $1", email)
        if not user:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

        # Update the user's password
        hashed_password = await get_password(request.new_password)
        
        # Update the user's password
        await db.execute(
            "UPDATE auth.auth_users SET password = $1 WHERE email = $2",
            hashed_password, email
        )

        return {"message": "Password reset successfully!"}

    except JWTError:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid token")
    except Exception as e:
        logger.error(f"Error resetting password: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Error: {str(e)}")
