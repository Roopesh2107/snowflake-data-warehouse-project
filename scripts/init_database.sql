/*
===========================================================
Create Database, Schemas, file format and policy tags
===========================================================
Script Purpose:


WARNING:



*/

-- Set the role to SYSADMIN to ensure sufficient permissions for creating warehouses, databases, schemas, and other objects.
use role sysadmin;

-- Create an ad-hoc warehouse with specific settings optimized for cost and efficiency.
-- The 'x-small' size is chosen for minimal resource usage, and auto-suspend (60 seconds) helps reduce costs by pausing the warehouse when not in use.
-- The warehouse is initially suspended to avoid unnecessary charges during initialization.
create warehouse if not exists adhoc_warehouse
     comment = 'This is the adhoc-wh'
     warehouse_size = 'x-small' 
     auto_resume = true 
     auto_suspend = 60 
     enable_query_acceleration = false 
     warehouse_type = 'standard' 
     min_cluster_count = 1 
     max_cluster_count = 1 
     scaling_policy = 'standard'
     initially_suspended = true;

-- Create a sandbox database for testing and staging data before moving to production.
create database if not exists sandbox;
use database sandbox;

-- Create schemas to organize data within the database.
-- 'stage_sch' is for staging raw data before transformations.
create schema if not exists stage_sch;
-- 'clean_sch' is for storing cleaned and processed data.
create schema if not exists clean_sch;
-- 'consumption_sch' is for data ready to be consumed by applications or analytics.
create schema if not exists consumption_sch;
-- 'common' is for shared resources like tags and policies.
create schema if not exists common;

use schema stage_sch;

-- Create a file format for CSV files to ensure consistent handling of file imports.
-- This format skips headers, uses commas as delimiters, and handles null values represented by '\N'.
create file format if not exists stage_sch.csv_file_format
    type = 'csv'
    compression = 'auto'
    field_delimiter = ','
    record_delimiter = '\n'
    skip_header = 1
    field_optionally_enclosed_by = '\042'
    null_if = ('\\N');

-- Create an internal stage to manage data uploads and downloads for the staging schema.
create stage stage_sch.csv_stg
    directory = (enable = true)
    comment = 'This is a Snowflake internal stage.';

-- Create a tag for classifying sensitive data with predefined allowed values.
create or replace tag
common.pii_policy_tag
allowed_values 'PII', 'PRICE', 'SENSITVE', 'EMAIL'
comment = 'This is a PII policy tag object.';

-- Create masking policies to protect sensitive data.
-- Masking policy for Personally Identifiable Information (PII).
create or replace masking policy
common.pii_masking_policy as (pii_text string)
returns string ->
to_varchar('** PII **');

-- Masking policy for email addresses.
create or replace masking policy
common.email_masking_policy as (email_text string)
returns string ->
to_varchar('** EMAIL **');

-- Masking policy for phone numbers.
-- This policy is used to mask phone numbers in scenarios where sensitive information must be hidden,
-- such as when sharing data with non-privileged users or for public reporting purposes.
create or replace masking policy
common.phone_masking_policy as (phone string)
returns string ->
to_varchar('** Phone **');
