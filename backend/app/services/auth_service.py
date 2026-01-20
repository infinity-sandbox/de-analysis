from typing import AsyncGenerator
from fastapi import HTTPException
from dotenv import load_dotenv
import os
import aiomysql
load_dotenv()
from typing import AsyncGenerator
from fastapi import HTTPException
import os
import asyncpg
from app.core.config import logger_settings, Settings
logger = logger_settings.get_logger(__name__)
from typing import Optional, List, Dict, Tuple
from datetime import datetime
from app.sql.main import SqlQuery
from asyncpg import Connection, Pool
import csv
import json


class AuthDatabaseService:
    @staticmethod
    async def connection():
        """
        Establishes a connection to the PostgreSQL database using asyncpg.
        Ensures the database exists, creating it if necessary.
        Returns:
            connection: asyncpg connection object.
        """
        try:
            # Connect to Postgres without specifying a database first
            initial_connection = await asyncpg.connect(
                host=logger_settings.AUTH_DB_HOST,
                user=logger_settings.AUTH_DB_USER,
                password=logger_settings.AUTH_DB_PASSWORD,
                port=int(logger_settings.AUTH_DB_PORT),
                database='postgres'  # default database
            )

            db_name = logger_settings.AUTH_DB
            # Check if database exists
            db_exists = await initial_connection.fetchval(
                "SELECT 1 FROM pg_database WHERE datname=$1", db_name
            )
            if not db_exists:
                await initial_connection.execute(f'CREATE DATABASE "{db_name}"')
                print(f"Database '{db_name}' created successfully.")

            await initial_connection.close()

            # Reconnect to the specified database
            connection = await asyncpg.connect(
                host=logger_settings.AUTH_DB_HOST,
                user=logger_settings.AUTH_DB_USER,
                password=logger_settings.AUTH_DB_PASSWORD,
                database=db_name,
                port=int(logger_settings.AUTH_DB_PORT)
            )
            return connection

        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error connecting to the database: {e}")

    @staticmethod
    async def get_db() -> AsyncGenerator[asyncpg.Connection, None]:
        """
        Provides an async database connection to FastAPI endpoints.
        Yields:
            asyncpg.Connection: Postgres connection instance.
        """
        connection = await AuthDatabaseService.connection()
        try:
            yield connection
        except Exception as e:
            raise RuntimeError(f"Session error: {e}")
        finally:
            await connection.close()

    _pool: Pool = None
    @classmethod
    async def get_pool(cls) -> Pool:
        if cls._pool is None:
            cls._pool = await asyncpg.create_pool(
                host=logger_settings.AUTH_DB_HOST,
                user=logger_settings.AUTH_DB_USER,
                password=logger_settings.AUTH_DB_PASSWORD,
                database=logger_settings.AUTH_DB,
                port=logger_settings.AUTH_DB_PORT,
                min_size=1,
                max_size=10
            )
        return cls._pool

    @staticmethod
    async def ping_database():
        """
        Pings the database to check if the connection is active.
        Returns:
            bool: True if the connection is successful, False otherwise.
        """
        try:
            connection = await AuthDatabaseService.connection()
            result = await connection.fetchval("SELECT 1")
            return result == 1
        except Exception:
            return False
        finally:
            await connection.close()

    @staticmethod
    async def auth_shutdown():
        """
        Close the Postgres connection during shutdown.
        """
        connection = await AuthDatabaseService.connection()
        await connection.close()
    
    @staticmethod
    async def insert_campaigns(csv_file: str, conn: asyncpg.Connection):
        # Open CSV
        with open(csv_file, newline='', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            rows = []
            for row in reader:
                # Clean numeric columns
                for col in ['Daily revenue','Sent','Non delivered','Hard bounces','Soft bounces',
                            'Delivered','Total opens','Opens','Apple MPP Opens','Total clicked','Clicked']:
                    row[col] = float(row[col]) if row[col] not in (None,'') else 0.0
                
                # Convert percentages to decimal
                for col in ['Non delivered rate','Trackable open rate','Click rate','Click-to-Open rate',
                            'Unsubscription rate','Delivered rate','Hard Bounces rate','Soft Bounces rate','Complaints rate']:
                    value = row.get(col)
                    if value is None or value == '':
                        row[col] = 0.0
                    else:
                        row[col] = float(value.strip('%')) / 100
                
                # Convert sending date
                row['Sending date'] = datetime.strptime(row['Sending date'], '%Y-%m-%d') if row['Sending date'] else None

                # JSON columns
                for col in ['Audience Segment A IDs','Audience Segment B IDs']:
                    val = row.get(col)
                    if val in (None,''):
                        row[col] = json.dumps([])
                    else:
                        try:
                            # ensure it's a list stored as string
                            row[col] = json.dumps(eval(val))
                        except Exception:
                            row[col] = json.dumps([])

                # Prepare tuple for insertion
                rows.append((
                    int(row['campaign_id']),
                    row['Campaign Name'],
                    row['audience_segment_a'],
                    row['audience_segment_b'],
                    row['Name from'],
                    row['Sending date'],
                    row['Daily revenue'],
                    row['Subject'],
                    int(row['Sent']),
                    int(row['Non delivered']),
                    int(row['Hard bounces']),
                    int(row['Soft bounces']),
                    row['Non delivered rate'],
                    int(row['Delivered']),
                    int(row['Total opens']),
                    int(row['Opens']),
                    row['Trackable open rate'],
                    int(row['Apple MPP Opens']),
                    int(row['Total clicked']),
                    int(row['Clicked']),
                    row['Click rate'],
                    row['Click-to-Open rate'],
                    int(row['Unsubscribed']),
                    row['Unsubscription rate'],
                    row['Delivered rate'],
                    row['Hard Bounces rate'],
                    row['Soft Bounces rate'],
                    int(row['Complaints']),
                    row['Complaints rate'],
                    row['Audience Segment A IDs'],
                    row['Audience Segment B IDs']
                ))

        # Insert query
        await conn.executemany(
            """
            INSERT INTO records.email_campaigns (
                campaign_id,campaign_name,audience_segment_a,audience_segment_b,name_from,sending_date,daily_revenue,
                subject,sent,non_delivered,hard_bounces,soft_bounces,non_delivered_rate,delivered,total_opens,opens,
                trackable_open_rate,apple_mpp_opens,total_clicked,clicked,click_rate,click_to_open_rate,unsubscribed,
                unsubscription_rate,delivered_rate,hard_bounces_rate,soft_bounces_rate,complaints,complaints_rate,
                audience_segment_a_ids,audience_segment_b_ids
            ) VALUES (
                $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$30,$31
            )
            """,
            rows
        )
        print(f"{len(rows)} campaign records inserted successfully.")
    
    @staticmethod
    async def insert_segments(csv_file: str, conn: asyncpg.Connection):
        with open(csv_file, newline='', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            rows = []
            for row in reader:
                rows.append((
                    int(row['Segment ID']),
                    row['Segment Name'],
                    row['Segment Folder'],
                    row['Logic Type'],
                    row['Filter 1 Type'],
                    row['Filter 1 Rule'],
                    row['Filter 1 Values'],
                    row['Connector 1'],
                    row['Filter 2 Type'],
                    row['Filter 2 Rule'],
                    row['Filter 2 Values'],
                    row['Connector 2'],
                    row['OR Filter 1 Type'],
                    row['OR Filter 1 Rule'],
                    row['OR Filter 1 Values'],
                    row['OR Filter 2 Type'],
                    row['OR Filter 2 Rule'],
                    row['OR Filter 2 Values'],
                    row['Uses Engagement'].strip().lower() == 'yes' if row['Uses Engagement'] else False,
                    row['Uses Date Rule'].strip().lower() == 'yes' if row['Uses Date Rule'] else False,
                    row['Notes']
                ))
        
        await conn.executemany(
            """
            INSERT INTO records.segments (
                segment_id,segment_name,segment_folder,logic_type,filter_1_type,filter_1_rule,filter_1_values,
                connector_1,filter_2_type,filter_2_rule,filter_2_values,connector_2,
                or_filter_1_type,or_filter_1_rule,or_filter_1_values,
                or_filter_2_type,or_filter_2_rule,or_filter_2_values,
                uses_engagement,uses_date_rule,notes
            ) VALUES (
                $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21
            )
            """,
            rows
        )
        print(f"{len(rows)} segment records inserted successfully.")
    
    @staticmethod
    async def ensure_data_exists():
        """
        Checks if the `records` schema exist and creates them if needed.
        """        
        try:
            connection = await AuthDatabaseService.connection()
            print("connected sucessfully")
            # Schema & Table creation
            create_table_files = [
                await SqlQuery.read_sql("com/de/data/create_schema"),
                await SqlQuery.read_sql("com/de/data/email_campaigns"),
                await SqlQuery.read_sql("com/de/data/segments"),
            ]
            
            for query in create_table_files:
                if query:
                    await connection.execute(query)
            print("tables are created successfully")
            PATH_CAMPAIGNS = os.path.join(logger_settings.DATA_DIR, f'2nd_cleaned_campaign_data.csv')
            PATH_SEGMENTS = os.path.join(logger_settings.DATA_DIR, f'1st_cleaned_segments.csv')

            await AuthDatabaseService.insert_campaigns(PATH_CAMPAIGNS, connection)
            await AuthDatabaseService.insert_segments(PATH_SEGMENTS, connection)

        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error ensuring table exists: {e}")
        finally:
            await connection.close()
            


    