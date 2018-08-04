CREATE SCHEMA [audit]
AUTHORIZATION [dbo]
GO
GRANT ALTER ON SCHEMA:: [audit] TO [db_apiETL]
GO
GRANT DELETE ON SCHEMA:: [audit] TO [db_apiETL]
GO
GRANT EXECUTE ON SCHEMA:: [audit] TO [db_apiETL]
GO
GRANT INSERT ON SCHEMA:: [audit] TO [db_apiETL]
GO
GRANT SELECT ON SCHEMA:: [audit] TO [db_apiETL]
GO
GRANT UPDATE ON SCHEMA:: [audit] TO [db_apiETL]
GO
GRANT ALTER ON SCHEMA:: [audit] TO [db_SSBDeveloper]
GO
GRANT DELETE ON SCHEMA:: [audit] TO [db_SSBDeveloper]
GO
GRANT EXECUTE ON SCHEMA:: [audit] TO [db_SSBDeveloper]
GO
GRANT INSERT ON SCHEMA:: [audit] TO [db_SSBDeveloper]
GO
GRANT SELECT ON SCHEMA:: [audit] TO [db_SSBDeveloper]
GO
GRANT UPDATE ON SCHEMA:: [audit] TO [db_SSBDeveloper]
GO
