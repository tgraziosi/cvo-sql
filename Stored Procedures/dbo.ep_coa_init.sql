SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE Proc [dbo].[ep_coa_init] As
BEGIN

	Declare @sAccountMask varchar(32), @sSeg1Mask varchar(32), @sSeg2Mask varchar(32), @sSeg3Mask varchar(32),
		@sSeg4Mask varchar(32), @sRefType varchar(8)
	Declare @iRefFlag int, @iSeg1Len int, @iSeg2Len int, @iSeg3Len int, @iSeg4Len int, @iSeqId int

	Declare @sAccountCode varchar(32),  @iInactiveDate int, 
		@iActiveDate int, @sInactiveDate varchar(20), @sActiveDate varchar(20)

	Declare @iValidAccount int, @iInvalidAccount int

	--Set up all the constant
	select @iValidAccount = 0, @iInvalidAccount = 1

	begin transaction
	--clean up temporary tables
	delete ep_temp_glchart
	delete ep_temp_glref_acct_type

	--delete epcoa table
	delete epcoa

	--Populate ep_temp_glchart
	insert into ep_temp_glchart ( account_code, account_description,
		account_type, currency_code, modified_dt, inactive_flag, 
		seg1_code, seg2_code, seg3_code, seg4_code)
	select account_code, account_description, account_type, currency_code, 
		getdate(), inactive_flag, seg1_code, seg2_code, seg3_code, seg4_code
	from glchart
	order by account_code 

	if ((select count(*) from ep_temp_glchart ) = 0) begin
		Rollback Transaction -- KRAS: this is a must for dbupdate
		Return		-- there is no account.  Return the process
	end


	--Need to convert active and inactive julian date to datetime string
	DECLARE dateconversion_cursor CURSOR FOR 
	SELECT g.account_code, g.inactive_date, g.active_date
	FROM glchart g
	Where g.inactive_date > 0 or g.active_date > 0
	order by account_code 

	OPEN dateconversion_cursor 
 
	FETCH NEXT FROM dateconversion_cursor 
	INTO @sAccountCode, @iInactiveDate, @iActiveDate
  
	WHILE @@FETCH_STATUS = 0
	BEGIN
		select 	@sInactiveDate = null,
			@sActiveDate = null

		if (@iInactiveDate <> 0)
			exec date2str_sp @iInactiveDate, @sInactiveDate out

		if (@iActiveDate <> 0)
			exec date2str_sp @iActiveDate, @sActiveDate out

		update ep_temp_glchart
		set 	inactive_dt = convert(datetime, @sInactiveDate, 0),
			active_dt = convert(datetime, @sActiveDate, 0)
		where account_code = @sAccountCode 

		-- Get the next account
		FETCH NEXT FROM dateconversion_cursor 
		INTO @sAccountCode, @iInactiveDate, @iActiveDate  
	END
  
	CLOSE dateconversion_cursor 
	DEALLOCATE dateconversion_cursor 

	--Set account to inactive when the inactive flag turn on
	update ep_temp_glchart
	set inactive_dt = getdate()
	where inactive_flag = 1


	--Populate ep_temp_glref_acct_type with reference flag equals
	--Excluded(1) or Required(3).  Note because Optional is 2 and it is the least priority,
	--therefor I have to change the reference flag for Optional from 2 to 4.
	Insert Into ep_temp_glref_acct_type (account_mask, reference_flag, reference_type)
		Select 	r.account_mask, r.reference_flag, 
			t.reference_type 
		From 	glrefact r, glratyp t 
		Where 	r.account_mask = t.account_mask and
			r.reference_flag in (1, 3)
		Order by reference_flag, r.account_mask

	Insert Into ep_temp_glref_acct_type (account_mask, reference_flag, reference_type)
		Select 	r.account_mask, 4, t.reference_type
		From 	glrefact r, glratyp t 
		Where 	r.account_mask = t.account_mask and
			r.reference_flag = 2
		Order by r.account_mask
	
	commit transaction

END




GO
GRANT EXECUTE ON  [dbo].[ep_coa_init] TO [public]
GO
