SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                





























CREATE PROCEDURE [dbo].[ccaupdate_sp]
AS
	CREATE TABLE #uncryptedaccts
	(
		
		id	int IDENTITY(1,1),
		company_code	varchar(8),
		order_no	int,
		order_ext	int,
		trx_ctrl_num	varchar(16),
		trx_type	varchar(16),
		customer_code	varchar(8),
		ccnumber	varchar(255),
		date_last_used	int
	)

	DECLARE @result 	int
	DECLARE @txt		varchar(255)
	DECLARE @buf		varchar(512)
	DECLARE	@strver		char(255)
	DECLARE	@pos		smallint
	DECLARE	@version	varchar(255)
	DECLARE	@SQLSERVER	varchar(255)
	DECLARE	@conrtoldb	varchar(255)
	DECLARE @svrinstdir 	varchar(255) 
	DECLARE @cmd		varchar(255)
	DECLARE @res		smallint

	
	IF (CHARINDEX('\',@@SERVERNAME)>0) 
		BEGIN

			SELECT @svrinstdir= SUBSTRING(@@SERVERNAME ,1,  CHARINDEX('\',@@SERVERNAME)-1) + '\'+
				SUBSTRING(@@SERVERNAME , CHARINDEX('\',@@SERVERNAME)+1, LEN(@@SERVERNAME)) + '\'
		END
	ELSE
		BEGIN
			
			SELECT @svrinstdir=  ''
		END 
	

	SELECT @buf = ''
	SELECT @res=0

	SELECT @conrtoldb = control_db FROM control_db_vw


	select @strver = @@version
	select @pos = patindex( '%.%', @strver )
	select @strver = substring(@strver, @pos-2, 2 )
	if ( ascii( @strver ) = 47 )
		select @strver = stuff( @strver, 1, 1, ' ' )
	select @version =convert( int, @strver )
	IF(@version = 7)
	BEGIN
		EXECUTE master..xp_regread 'HKEY_LOCAL_MACHINE','SOFTWARE\Microsoft\MSSQLServer\Setup',     
	     	'SQLPath', @SQLSERVER OUTPUT  
	END
	IF(@version = 8)
	BEGIN
		EXECUTE master..xp_regread 'HKEY_LOCAL_MACHINE','SOFTWARE\Microsoft\Microsoft SQL Server\80\Tools\ClientSetup',     
	     	'SQLPath', @SQLSERVER OUTPUT  
	END
	
	IF(@version = 9)
	BEGIN
		EXECUTE master..xp_regread 'HKEY_LOCAL_MACHINE','SOFTWARE\Microsoft\Microsoft SQL Server\90\Tools\ClientSetup',     
	     	'SQLPath', @SQLSERVER OUTPUT  
	END

	IF(@version = 10)
	BEGIN
		EXECUTE master..xp_regread 'HKEY_LOCAL_MACHINE','SOFTWARE\Microsoft\Microsoft SQL Server\100\Tools\ClientSetup',     
	     	'SQLPath', @SQLSERVER OUTPUT  
	END


	SET @cmd = 'cd "' + @SQLSERVER + '\security keys\'+ @svrinstdir+ @conrtoldb + '"' /* Rev 1.1 */
	EXEC @res = master..xp_cmdshell @cmd, NO_OUTPUT
	IF (@res=1)
	BEGIN
		SET @res=0
		SET @cmd = 'md "' + @SQLSERVER + '\security keys\' + @svrinstdir+ @conrtoldb + '"' /* Rev 1.1*/
		EXEC @res = master..xp_cmdshell @cmd, NO_OUTPUT
		IF(@res=1)
		BEGIN
			print 'SQL server is not instaled or path was not found '
			RETURN 
		END
	END
	SET @res=0

	


	IF ((SELECT COUNT(pub_key) from CVO_Control..ccakeys) < 1)
	BEGIN
		DELETE CVO_Control..ccakeys WHERE pub_key IS NULL

		SELECT @txt = dbo.CCAGenerateKeys_fn() 
	
		IF( (SELECT COUNT(pub_key) FROM CVO_Control..ccakeys) > 0 )
			UPDATE CVO_Control..ccakeys SET pub_key = @txt
		ELSE
			INSERT CVO_Control..ccakeys VALUES ( @txt )
	
		IF( (SELECT COUNT(control_db) FROM ccaconfig) > 0 )
			UPDATE CVO_Control..ccaconfig SET date_last_key_generation = datediff( day, '01/01/1900', getdate()) + 693596
		ELSE
			INSERT CVO_Control..ccaconfig (control_db,admin1, admin2, admin3,days_gen_keys, days_purge_accts,days_purge_log, date_last_key_generation,date_last_account_purge,date_last_log_purge,last_changed_user) values ('CVO_Control','','','',0,0,0,datediff( day, '01/01/1900', getdate()) + 693596,0,0,'')
	END

	


	BEGIN TRANSACTION cpy

	INSERT #uncryptedaccts
	SELECT co.company_code,'','',tmp.trx_ctrl_num,'2031',tmp.customer_code,tmp.prompt2_inp, datediff( day, '01/01/1900', getdate()) + 693596
	FROM arinptmp tmp, icv_cctype icv, glco co
	WHERE ISNULL(tmp.prompt2_inp, '')<>''
	AND tmp.payment_code =  icv.payment_code
	AND SUBSTRING(tmp.prompt2_inp, 3, 1) <> '*'
	
	INSERT #uncryptedaccts
	SELECT co.company_code,'','',pyt.trx_ctrl_num,pyt.trx_type,pyt.customer_code,pyt.prompt2_inp, datediff( day, '01/01/1900', getdate()) + 693596
	FROM arinppyt pyt, icv_cctype icv, glco co
	WHERE ISNULL(pyt.prompt2_inp, '')<>''
	AND pyt.payment_code =  icv.payment_code
	AND SUBSTRING(pyt.prompt2_inp, 3, 1) <> '*'

	INSERT #uncryptedaccts
	SELECT co.company_code,'','',trx.trx_ctrl_num,trx.trx_type,trx.customer_code,trx.prompt2_inp, datediff( day, '01/01/1900', getdate()) + 693596
	FROM artrx trx, icv_cctype icv, glco co
	WHERE ISNULL(trx.prompt2_inp, '')<>''
	AND trx.payment_code =  icv.payment_code
	AND SUBSTRING(trx.prompt2_inp, 3, 1) <> '*'
	
	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'ord_payment' )  
	BEGIN
		SELECT @buf = 'INSERT #uncryptedaccts
		SELECT co.company_code,opay.order_no,opay.order_ext,'''','''',ord.cust_code,opay.prompt2_inp, datediff( day, ''01/01/1900'', getdate()) + 693596
		FROM ord_payment opay, orders ord, icv_cctype icv, glco co
		WHERE ISNULL(opay.prompt2_inp, '''')<>''''
		AND opay.payment_code =  icv.payment_code
		AND opay.order_no = ord.order_no
		AND opay.order_ext = ord.ext
		AND SUBSTRING(opay.prompt2_inp, 3, 1) <> ''*'''

		EXEC (@buf)
	END

	INSERT #uncryptedaccts
	SELECT co.company_code,'','',trx.customer_code+ trx.payment_code,2748,trx.customer_code,trx.prompt2, datediff( day, '01/01/1900', getdate()) + 693596
	FROM icv_ccinfo trx, icv_cctype icv, glco co
	WHERE ISNULL(trx.prompt2, '')<>''
	AND trx.payment_code =  icv.payment_code
	AND SUBSTRING(trx.prompt2, 3, 1) <> '*'

	



	EXEC @result = CVO_Control..ccarenewcryptaccts_sp

	IF @result <> 0
	BEGIN
		ROLLBACK TRANSACTION cpy
		RETURN -1
	END

	COMMIT TRANSACTION cpy

	


	UPDATE arinptmp
	SET prompt2_inp = dbo.CCAMask_fn(prompt2_inp)
	FROM arinptmp tmp, icv_cctype icv
	WHERE ISNULL(tmp.prompt2_inp, '')<>''
	AND tmp.payment_code =  icv.payment_code

	UPDATE arinppyt
	SET prompt2_inp = dbo.CCAMask_fn(prompt2_inp)	
	FROM arinppyt pyt, icv_cctype icv
	WHERE ISNULL(pyt.prompt2_inp, '')<>''
	AND pyt.payment_code =  icv.payment_code

	UPDATE artrx
	SET prompt2_inp = dbo.CCAMask_fn(prompt2_inp)	
	FROM artrx trx, icv_cctype icv
	WHERE ISNULL(trx.prompt2_inp, '')<>''
	AND trx.payment_code =  icv.payment_code

	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'ord_payment' )  
	BEGIN
		SELECT @buf = 'UPDATE ord_payment
		SET prompt2_inp = dbo.CCAMask_fn(prompt2_inp)	
		FROM ord_payment opay, orders ord, icv_cctype icv
		WHERE ISNULL(opay.prompt2_inp, '''')<>''''
		AND opay.payment_code =  icv.payment_code
		AND opay.order_no = ord.order_no
		AND opay.order_ext = ord.ext'
	
		EXEC (@buf)
	END

	UPDATE icv_ccinfo
	SET prompt2 = dbo.CCAMask_fn(prompt2),
	    trx_ctrl_num = customer_code + payment_code,
	    trx_type= 2748

	UPDATE icv_cchistory
	SET account = dbo.CCAMask_fn(account)
	WHERE ISNULL(account, '') <> ''

	



	DELETE icv_log

	PRINT 'The command(s) completed successfully.'

	RETURN 0
GO
GRANT EXECUTE ON  [dbo].[ccaupdate_sp] TO [public]
GO
