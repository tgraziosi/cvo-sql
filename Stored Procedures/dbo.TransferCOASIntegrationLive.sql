SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[TransferCOASIntegrationLive]
AS

EXEC master..xp_servicecontrol 'STOP', 'SQLServerAgent'

CREATE TABLE #TEMPInfo1
(
	timestamp			timestamp,
	account_code		varchar(32),
	account_description	varchar(40),
	account_type		smallint
)

CREATE TABLE #TEMPInfo2
(
	timestamp			timestamp,
	account_code		varchar(32),
	account_description	varchar(40),
	account_type		smallint
)

UPDATE glratyp SET reference_type = reference_type
UPDATE glref SET description = description

UPDATE epintegrationrecs SET action = 'I'

EXEC integrationchecknewrec_sp

INSERT INTO #TEMPInfo1 (	account_code,			account_description,			account_type)
SELECT CHRT.account_code,			CHRT.account_description,			CHRT.account_type
FROM glchart CHRT

DECLARE @flag INTEGER
DECLARE @first_account VARCHAR(32)
DECLARE @last_account VARCHAR(32)

SET @flag = 1

WHILE (@flag = 1)
BEGIN
	
	INSERT INTO #TEMPInfo2 (	account_code,			account_description,			account_type)
	SELECT TOP 3500 CHRT.account_code,			CHRT.account_description,			CHRT.account_type
	FROM #TEMPInfo1 CHRT

	SET @first_account = (SELECT TOP 1 account_code FROM #TEMPInfo2 ORDER BY account_code ASC)
	SET @last_account = (SELECT TOP 1 account_code FROM #TEMPInfo2 ORDER BY account_code DESC)
	
	PRINT 'FIRST ACCOUNT ' + @first_account + ' LAST ACCOUNT ' + @last_account

	UPDATE glchart 
		SET account_description = account_description
	WHERE account_code BETWEEN @first_account AND @last_account

	UPDATE epintegrationrecs SET action = 'I'

	EXEC integrationchecknewrec_sp

	DELETE INFO1
	FROM #TEMPInfo1 INFO1
		INNER JOIN #TEMPInfo2 INFO2 ON INFO1.account_code = INFO2.account_code

	DELETE #TEMPInfo2

	IF NOT EXISTS (SELECT TOP 1 * FROM #TEMPInfo1)
	BEGIN
		BREAK
	END
END

DROP TABLE #TEMPInfo1
DROP TABLE #TEMPInfo2

EXEC master..xp_servicecontrol 'START', 'SQLServerAgent'
GO
GRANT EXECUTE ON  [dbo].[TransferCOASIntegrationLive] TO [public]
GO
