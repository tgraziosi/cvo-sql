SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

	CREATE PROCEDURE [dbo].[EncDecCC] (@PONumber varchar(18), @CCNum varchar(180))

	As
	/*
	   Copyright Epicor Software 2003. All Rights Reserved. 
	*/
	BEGIN
		DECLARE @object int
		DECLARE @hr int
		DECLARE @src varchar(255), @desc varchar(255)
		DECLARE @CC_num varchar(180)


		EXEC @hr = sp_OACreate 'CRUFLEncrypt.KrEncrypt', @object OUT, 1
		IF @hr <> 0
		BEGIN
			EXEC sp_OAGetErrorInfo @object, @src OUT, @desc OUT 
			raiserror('Error Creating COM Component 0x%x, %s, %s',16,1, @hr, @src, @desc)
			RETURN
		END

		DECLARE @property varchar(255)

		EXEC @hr = sp_OAMethod @object, 'DecryptStr', @property OUT, @sEncryptedStr = @CCNum
		IF @hr <> 0
		BEGIN	
			EXEC sp_OAGetErrorInfo @object, @src OUT, @desc OUT, @CCNum out
			RETURN
		END

		--PRINT @property

		select @CC_num = @property

		insert into #TEMPCCnum (TempPO_num, TempCC_num)
			select @PONumber, @CC_num

		--select * from #TEMPCCnum

		EXEC @hr = sp_OADestroy @object
		IF @hr <> 0
		BEGIN
			EXEC sp_OAGetErrorInfo @object, @src OUT, @desc OUT 
			RETURN
		END

		
	END
	
GO
GRANT EXECUTE ON  [dbo].[EncDecCC] TO [public]
GO
