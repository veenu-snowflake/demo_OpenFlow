--Step 2.1: Grant REPLICATION Privilege
-- Grant replication to your application user
ALTER ROLE application WITH REPLICATION;


--Step 2.2: Create Publication
 CREATE PUBLICATION openflow_publication FOR TABLE 
      public.app_user_common_datatype,
      public.orders,
      public.customers;

--Step 2.3: Set REPLICA IDENTITY
ALTER TABLE public.app_user_common_datatype REPLICA IDENTITY FULL;
ALTER TABLE public.orders REPLICA IDENTITY FULL;
ALTER TABLE public.customers REPLICA IDENTITY FULL;

------ SCRIPT ENDS HERE--------







 -- Verify (should show 'f' for FULL)
 SELECT relname, relreplident 
 FROM pg_class 
 WHERE relname IN ('app_user_common_datatype', 'orders', 'customers');


-- Option A: Publish ALL tables (recommended for simplicity)
CREATE PUBLICATION openflow_publication FOR ALL TABLES;
SELECT rolname, rolreplication FROM pg_roles WHERE rolname = 'application';
-- Should show: application | t

-- Verify
SELECT * FROM pg_publication;
SELECT * FROM pg_publication_tables;