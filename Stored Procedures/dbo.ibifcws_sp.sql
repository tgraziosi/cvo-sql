SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2007 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2007 Epicor Software Corporation, 2007    
                  All Rights Reserved                    
*/                                                






























	
CREATE PROC [dbo].[ibifcws_sp]
	@debug_flag 	int,
	@InterBranchXml	ntext
AS

-->>>======================Init===========================

-- #include "STANDARD DECLARES.INC"





































DECLARE @rowcount		INT
DECLARE @error			INT
DECLARE @errmsg			VARCHAR(128)
DECLARE @log_activity		VARCHAR(128)
DECLARE @procedure_name		VARCHAR(128)
DECLARE @location		VARCHAR(128)
DECLARE @buf			VARCHAR(1000)
DECLARE @ret			INT
DECLARE @text_value		VARCHAR(255)
DECLARE @int_value		INT
DECLARE @return_value		INT
DECLARE @transaction_started	INT
DECLARE @version			VARCHAR(128)
DECLARE @len				INTEGER
DECLARE @i				INTEGER

-- end "STANDARD DECLARES.INC"

DECLARE @hDoc int
DECLARE @ret_status int
SELECT @hDoc = 0, @ret_status = 0
SET @procedure_name = 'ibifcws_sp'

    -- #include "STANDARD ENTRY.INC"
    SET NOCOUNT ON
    SELECT @location = @procedure_name + ': Location ' + 'STANDARD ENTRY' + ', line: ' + RTRIM(LTRIM(STR(3))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
    SELECT @version='1.0'
    IF @debug_flag > 0
        BEGIN
        SELECT 'PS_SIGNAL'='DIAGNOSTIC ON'
        END
    SELECT @buf = @procedure_name + ': Entry (version ' + @version + ') at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END
    SELECT @return_value = 0, @transaction_started = 0
    -- end "STANDARD ENTRY.INC"


-->>>==================Create Temp Tables=================
SELECT @location = @procedure_name + ': Location ' + 'Create #ibio_schema Table' + ', line: ' + RTRIM(LTRIM(STR(45))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
CREATE TABLE #ibio_schema (
	DocumentReferenceID		int,
	DocumentType		nvarchar(5),
	DocDescription		nvarchar(1024),
	id		uniqueidentifier,
	state_flag		int,
	date_entered		nvarchar(19), 
	date_applied		nvarchar(19), 
	trx_type		int,
	from_orgid		nvarchar(30),
	to_orgid		nvarchar(30),
	amount		decimal(20,8),
	currency_code		nvarchar(16),
	tax_code		nvarchar(8),
	ar_account_code		nvarchar(32),
	rev_account_code		nvarchar(32),
	ap_account_code		nvarchar(32),
	exp_account_code		nvarchar(32),
	link1		nvarchar(1024),
	link2		nvarchar(1024),
	link3		nvarchar(1024),
	username		nvarchar(256)
)

    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END


SELECT @location = @procedure_name + ': Location ' + 'Create #ibio Table' + ', line: ' + RTRIM(LTRIM(STR(71))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
CREATE TABLE #ibio(
	DocumentReferenceID		int,
	id		uniqueidentifier,
	state_flag		int,
	date_entered		datetime,
	date_applied		datetime,
	trx_type		int,
	controlling_org_id		nvarchar(30),
	detail_org_id		nvarchar(30),
	amount		decimal(20,8),
	currency_code		nvarchar(16),
	tax_code		nvarchar(8),
	recipient_code		nvarchar(32),
	originator_code		nvarchar(32),
	tax_payable_code		nvarchar(32),
	tax_expense_code		nvarchar(32),
	link1		nvarchar(1024),
	link2		nvarchar(1024),
	link3		nvarchar(1024),
	username		nvarchar(256),
	reference_code		nvarchar(32)
)

    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END


SELECT @location = @procedure_name + ': Location ' + 'Create #iberror Table' + ', line: ' + RTRIM(LTRIM(STR(96))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
CREATE TABLE #iberror(
	id		uniqueidentifier,
	error_code		int,
	info1		nvarchar(255),
	info2		nvarchar(255),
	infoint		int,
	infodecimal		decimal(20,8),
	link1		nvarchar(1024),
	link2		nvarchar(1024),
	link3		nvarchar(1024),
)

    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END


-->>>================Populate Temp Tables=================
SELECT @location = @procedure_name + ': Location ' + 'Prepare XML document' + ', line: ' + RTRIM(LTRIM(STR(111))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
EXEC @ret_status=sp_xml_preparedocument @hDoc OUTPUT, @InterBranchXml

    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END

IF @ret_status<>0 
BEGIN 
	SELECT @buf = 'ERROR: Error number '+RTRIM(LTRIM(STR(@ret_status)))+' has occurred at '+@location
	RAISERROR(@buf,16,1)
	RETURN -100
END

SELECT @location = @procedure_name + ': Location ' + 'Populate Schema Table' + ', line: ' + RTRIM(LTRIM(STR(121))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
INSERT INTO #ibio_schema (
	DocumentReferenceID,
	DocumentType, 
	DocDescription, 
	id, 
	state_flag, 
	date_entered, 
	date_applied, 
	trx_type, 
	from_orgid, 
	to_orgid, 
	amount, 
	currency_code, 
	tax_code, 
	ar_account_code, 
	rev_account_code, 
	ap_account_code, 
	exp_account_code, 
	link1, 
	link2, 
	link3, 
	username
)
SELECT 
	DocumentReferenceID,
	DocumentType, 
	DocDescription, 
	NEWID(),  		
	NULL, 
	date_entered,
	date_applied,
	trx_type, 
	from_orgid, 
	to_orgid, 
	amount, 
	currency_code, 
	tax_code, 
	ar_account_code, 
	rev_account_code, 
	ap_account_code, 
	exp_account_code, 
	link1, 
	link2, 
	link3,
	NULL
FROM OPENXML(@hDoc,'/CreateInterBranchDoc/InterBranchDoc',2)
WITH #ibio_schema

    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END


IF @hDoc<>0 
BEGIN 
	SELECT @location = @procedure_name + ': Location ' + 'Remove XML document' + ', line: ' + RTRIM(LTRIM(STR(173))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	EXEC sp_xml_removedocument @hDoc
	
    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END

END

SELECT @location = @procedure_name + ': Location ' + 'Load data into #ibio' + ', line: ' + RTRIM(LTRIM(STR(178))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
INSERT INTO #ibio (
	DocumentReferenceID,
	id, 
	state_flag, 
	date_entered, 
	date_applied, 
	trx_type, 
	controlling_org_id, 
	detail_org_id, 
	amount, 
	currency_code, 
	tax_code, 
	recipient_code,
	originator_code,
	tax_payable_code,
	tax_expense_code,
	link1, 
	link2, 
	link3, 
	username,
	reference_code		
)
SELECT 
	DocumentReferenceID,
	id, 
	state_flag, 
	Convert(datetime, date_entered),
	Convert(datetime, date_applied),
	trx_type, 
	from_orgid, 
	to_orgid, 
	amount, 
	currency_code, 
	tax_code, 
	ar_account_code, 
	rev_account_code, 
	ap_account_code, 
	exp_account_code, 
	link1, 
	link2, 
	link3, 
	username,
	''			
FROM #ibio_schema

    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END


-->>>================Call Stored Procedure================
SELECT @location = @procedure_name + ': Location ' + 'Call ibifc_sp' + ', line: ' + RTRIM(LTRIM(STR(226))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
SELECT @ret_status = 0
EXEC @ret_status = ibifc_sp @bulk_flag = 1, @debug_flag = @debug_flag 

    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END



IF @ret_status <> 0
BEGIN
   SET ROWCOUNT 0
   INSERT INTO #iberror (  [id],        [error_code],           [info1],
               [info2],    [infoint],   [infodecimal],		[link1],    
	       [link2],    [link3])
   
   SELECT 		   [id],    	@ret_status,    	'',
       		'',    	   0,        	0.0,			'',    
		'',        ''
   FROM #ibio
   SET ROWCOUNT 0
END


-->>>=================Form Resulting XML==================
SELECT '$FIN_RESULTS$' --Keyword for the result parser
IF EXISTS(Select 1 from #iberror)
	SELECT @ret_status=CASE @ret_status WHEN 0 THEN -1 ELSE @ret_status END

SELECT '<STATUS>'+convert(varchar, @ret_status)+'</STATUS>'

SELECT '<CreateInterBranchDoc>'

SELECT 
	InterBranchDoc.DocumentReferenceID as DocumentReferenceID, 
	CASE WHEN RTRIM(LTRIM(s.DocumentType))='' THEN NULL ELSE s.DocumentType END as DocumentType, 
	CASE WHEN RTRIM(LTRIM(s.DocDescription))='' THEN NULL ELSE s.DocDescription END as DocDescription, 
	InterBranchDoc.id as id, 
	InterBranchDoc.state_flag as state_flag, 
	InterBranchDoc.date_entered as date_entered, 
	InterBranchDoc.date_applied as date_applied, 
	InterBranchDoc.trx_type as trx_type, 
	InterBranchDoc.controlling_org_id as from_orgid, 
	InterBranchDoc.detail_org_id as to_orgid, 
	InterBranchDoc.amount as amount, 
	InterBranchDoc.currency_code as currency_code, 
	InterBranchDoc.tax_code as tax_code, 
	InterBranchDoc.recipient_code as ar_account_code, 
	InterBranchDoc.originator_code as rev_account_code, 
	InterBranchDoc.tax_payable_code as ap_account_code, 
	InterBranchDoc.tax_expense_code as exp_account_code, 
	InterBranchDoc.link1 as link1, 
	InterBranchDoc.link2 as link2, 
	InterBranchDoc.link3 as link3, 
	InterBranchDoc.username as username
FROM #ibio as InterBranchDoc, #ibio_schema s
WHERE InterBranchDoc.DocumentReferenceID = s.DocumentReferenceID
AND	 InterBranchDoc.id not in (SELECT id FROM #iberror)
FOR XML AUTO, ELEMENTS

IF EXISTS(Select 1 from #iberror)
BEGIN

	SELECT 
		CASE WHEN RTRIM(LTRIM(DocumentReferenceID))='' THEN NULL ELSE i.DocumentReferenceID END as DocumentReferenceID, 
		Error.error_code as ErrorCode, 
		cast(ISNULL(d.etext,'No description') as varchar(255)) as ErrorDescription,
		Error.info1 as info1, 
		Error.info2 as info2, 
		Error.infoint as infoint, 
		Error.infodecimal as infodecimal, 
		Error.link1 as link1, 
		Error.link2 as link2, 
		Error.link3 as link3
	FROM #ibio as i
	INNER JOIN  #iberror as Error
		ON i.id = Error.id 
	LEFT JOIN  ibedterr as d
		ON d.code = Error.error_code
	FOR XML AUTO, ELEMENTS

END
SELECT '</CreateInterBranchDoc>'

-->>>==========================End========================
SELECT @location = @procedure_name + ': Location ' + 'Drop table #ibio' + ', line: ' + RTRIM(LTRIM(STR(308))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
DROP TABLE #ibio

    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END

SELECT @location = @procedure_name + ': Location ' + 'Drop table #iberror' + ', line: ' + RTRIM(LTRIM(STR(311))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
DROP TABLE #iberror

    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END

SELECT @location = @procedure_name + ': Location ' + 'Drop table #ibio_schema' + ', line: ' + RTRIM(LTRIM(STR(314))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
DROP TABLE #ibio_schema

    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END



    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

/**/                                              
GO
GRANT EXECUTE ON  [dbo].[ibifcws_sp] TO [public]
GO
