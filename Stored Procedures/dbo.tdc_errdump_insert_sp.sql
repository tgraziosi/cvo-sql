SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_errdump_insert_sp]
	@strServerName			VARCHAR(50),
	@strDataName 			VARCHAR(50),
	@strUserID			VARCHAR(50),
	@strComputer			VARCHAR(50),
	@numErrID			NUMERIC ,
	@strErrDescription		VARCHAR(255),
	@strRoutine			VARCHAR(255),
	@strSQLString			TEXT = ''
AS

INSERT INTO tdc_errdump (LogDate,ServerName,DataName,UserID,Computer,ErrID,ErrDescription,Routine,SQLString)
	VALUES(	getdate() , 		@strServerName,		@strDataName, 
		@strUserID, 		@strComputer, 		@numErrID, 
		@strErrDescription, 	@strRoutine,		@strSQLString)

RETURN


GO
GRANT EXECUTE ON  [dbo].[tdc_errdump_insert_sp] TO [public]
GO
