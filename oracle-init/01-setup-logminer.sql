-- Set archive log destination
ALTER SYSTEM SET db_recovery_file_dest_size = 10G;
ALTER SYSTEM SET db_recovery_file_dest = '/opt/oracle/oradata/recovery_area' scope=spfile;
ALTER SYSTEM SET enable_goldengate_replication=true;

SHUTDOWN IMMEDIATE
STARTUP MOUNT
ALTER DATABASE ARCHIVELOG;
ALTER DATABASE OPEN;
ARCHIVE LOG LIST;

-- Enable minimal supplemental logging
ALTER DATABASE ADD SUPPLEMENTAL LOG DATA;

EXIT;
