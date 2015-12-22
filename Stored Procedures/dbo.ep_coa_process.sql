SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE Proc [dbo].[ep_coa_process] @sFromDate varchar(30), @sToDate varchar(30), @sAccountLowerBound varchar(32), 
	@sAccountUpperBound varchar(32), @iAccountType SmallInt, @sRefLowerBound varchar(32), 
	@sRefUpperBound varchar(32), @sInputRefType varchar(32), @sAsOfDate varchar(30), @iActiveFlag smallInt
AS BEGIN

	Declare @sAccountMask varchar(32), @sSeg1Mask varchar(32), @sSeg2Mask varchar(32), @sSeg3Mask varchar(32),
		@sSeg4Mask varchar(32), @sRefType varchar(8)
	Declare @iRefFlag int, @iSeg1Len int, @iSeg2Len int, @iSeg3Len int, @iSeg4Len int, @iSeqId int

	Declare @sAccountCode varchar(32),  @iInactiveDate int, 
		@iActiveDate int, @sInactiveDate varchar(20), @sActiveDate varchar(20)

	Declare @iValidAccount int, @iInvalidAccount int

	Declare @sSQL varchar(8000), @sWhereClause varchar(1500), @org_count_temp_glchart int,
		@count_temp_glchart int

	Declare @sSQL_Result_Where varchar(1000)

	--Build a result where clause for having Reference code
	if (@sInputRefType > '')
		select @sSQL_Result_Where = ' (t.reference_type = ''' + @sInputRefType + ''') ' 

	if (@sRefLowerBound  > '')
	    if ((select isnumeric(@sRefLowerBound)) = 1)  --Case reference code is numeric
		if (@sSQL_Result_Where > '')
			select @sSQL_Result_Where = @sSQL_Result_Where + 
				' AND (t.reference_code >= ' + @sRefLowerBound + ') '
		ELSE
			select @sSQL_Result_Where = ' (t.reference_code >= ' + 
				@sRefLowerBound + ') '
	    ELSE
		if (@sSQL_Result_Where > '')
			select @sSQL_Result_Where = @sSQL_Result_Where + 
				' AND (t.reference_code >= ''' + @sRefLowerBound + ''') '
		ELSE
			select @sSQL_Result_Where = ' (t.reference_code >= ''' + 
				@sRefLowerBound + ''') '
	
	if (@sRefUpperBound > '')
	    if ((select isnumeric(@sRefUpperBound)) = 1)  --Case reference code is numeric
		if (@sSQL_Result_Where > '')
			select @sSQL_Result_Where = @sSQL_Result_Where + 
				' AND (t.reference_code <= ' + @sRefUpperBound + ') '
		ELSE
			select @sSQL_Result_Where = ' (t.reference_code >= ' + 
				@sRefUpperBound + ') '
	    ELSE
		if (@sSQL_Result_Where > '')
			select @sSQL_Result_Where = @sSQL_Result_Where + 
				' AND (t.reference_code <= ''' + @sRefUpperBound + ''') '
		ELSE
			select @sSQL_Result_Where = ' (t.reference_code >= ''' + 
				@sRefUpperBound + ''') '


	IF (@sSQL_Result_Where > '')
		select @sSQL_Result_Where = ' ((t.reference_code is null) OR (' +
			@sSQL_Result_Where + '))'
	
	--This temp table will be use for result set only
	CREATE table #temp_result_set( 
		company_name varchar(30),
		company_id smallint,
		guid varchar(50),
		account_code varchar(32),
		account_description varchar(40),
		reference_code varchar(32),
		reference_description varchar(40),
		modified_dt datetime,
		active_dt datetime,
		inactive_dt datetime,
		currency_code varchar(8),
		account_type smallint,
		system_date datetime,
		reference_type varchar(8))

	CREATE table #temp_glchart( 
		account_code varchar(32),
		account_description varchar (40),
		active_dt datetime,
		inactive_dt datetime,
		modified_dt datetime,
		inactive_flag smallint,
		currency_code varchar(8),
		account_type smallint,
		seg1_code varchar(32),
		seg2_code varchar(32),
		seg3_code varchar(32),
		seg4_code varchar(32),
		modified_flg smallint default(0))

	--Build a Dynamic SQL
	select @sSQL = 'select account_code, account_description, active_dt, inactive_dt, modified_dt, ' +
		' inactive_flag, currency_code, account_type, ' +
		'seg1_code, seg2_code, seg3_code, seg4_code ' +
		' from ep_temp_glchart '

	-- Build a where clause
	if (@sToDate > '') 
		select @sWhereClause = ' (modified_dt <= ''' + @sToDate + ''') '
	else
		select @sWhereClause = ' (modified_dt <= getdate()) '
	
	if (@sFromDate > '') select @sWhereClause =  @sWhereClause + ' AND ' + 
		' (modified_dt >= ''' + @sFromDate + ''') '	 
		
	if (@sAccountLowerBound > '') 
		select @sWhereClause = @sWhereClause + ' AND ' + ' (account_code >= ''' + @sAccountLowerBound + ''') '

	if (@sAccountUpperBound > '') 
		select @sWhereClause = @sWhereClause + ' AND ' + ' (account_code <= ''' + @sAccountUpperBound + ''') '

	if (@iAccountType is not null) 
		select @sWhereClause = @sWhereClause  + ' AND ' + ' (account_type = ' + 
			cast(@iAccountType as varchar(10)) + ') '

	if (@sWhereClause > '') select @sSQL = @sSQL + ' Where ' + @sWhereClause

	--Populate #temp_glchart table
	insert #temp_glchart ( account_code, account_description, active_dt, inactive_dt, modified_dt,
		inactive_flag, currency_code, account_type, 
		seg1_code, seg2_code, seg3_code, seg4_code )
	exec ( @sSQL )
	
	--Get the orginal count for temp_glchart
	select @org_count_temp_glchart = count(*) from #temp_glchart 

	--Case of not finding any glchart, return
--	if ( @org_count_temp_glchart = 0 ) RETURN

	select @count_temp_glchart = count(*) 
	from #temp_glchart g, epcoa e
	Where 	e.account_code = g.account_code and
		e.modified_dt = g.modified_dt and
		e.reference_code is null

	--Case of no change in glchart, return epcoa set of records or	
	--if there is no records in ep_temp_glref_acct_type, it indicates that the
	--account mask in glratyp table need to be populate before calling this process
	if ((@org_count_temp_glchart = @count_temp_glchart) or
	((select count(*) from ep_temp_glref_acct_type) = 0))
	Begin
		--If reference account mask has not set up, need to insert coa into epcoa table if it's not exist.
		if ((select count(*) from ep_temp_glref_acct_type) = 0)
		Begin	
			--Copy all records from temp_glchart to epcoa with no reference code
			insert into epcoa 
				(guid, account_code, account_description, active_dt, inactive_dt, 
				 modified_dt)
			select newid(), g.account_code, g.account_description, g.active_dt, g.inactive_dt, 
				g.modified_dt
			from #temp_glchart g
			where g.modified_flg = 0 and
				g.account_code not in
					(select account_code from epcoa 
					 where 	epcoa.account_code = g.account_code and
							epcoa.reference_code is null and
							epcoa.deleted_dt is null)
		End
			
		if  (@sSQL_Result_Where > '')
		Begin
			--Insert into the temp table
			Insert into #temp_result_set( company_name, company_id,	guid, account_code,
				account_description, reference_code, reference_description, 
				modified_dt, active_dt, inactive_dt, currency_code, account_type,
				system_date)
			SELECT co.company_name, co.company_id, e.guid, e.account_code, 
		 		e.account_description, e.reference_code, e.reference_description, 
		 		e.modified_dt, e.active_dt, e.inactive_dt, g.currency_code, 
		 		g.account_type, getdate() AS system_date 
            		FROM epcoa e, glco co, #temp_glchart g 
            		WHERE  	g.account_code = e.account_code and
				((@iActiveFlag = 0 and e.inactive_dt <= @sAsOfDate) or	-- Case of inactive
				 (@iActiveFlag = 1 and (e.inactive_dt is null or e.inactive_dt > @sAsOfDate) and
					(e.active_dt is null or e.active_dt <= @sAsOfDate)) or	--Case of Active
				 (@iActiveFlag = 2)) 		--Case of Both
			UNION
			SELECT co.company_name, co.company_id, e.guid, e.account_code, 
		 		e.account_description, e.reference_code, e.reference_description, 
		 		e.modified_dt, e.active_dt, e.inactive_dt, "", 
		 		"", getdate() AS system_date 
            		FROM epcoa e, glco co
            		WHERE  	(e.deleted_dt is not null  or 
				 e.send_inactive_flg = 1)
				order by e.inactive_dt, e.account_code

			--Clean up the #temp_result_set
			if (@sRefLowerBound > '')
	    		    if ((select isnumeric(@sRefLowerBound)) = 1)  --Case reference code is numeric
				delete #temp_result_set
				where reference_code < cast(@sRefLowerBound as int)
			    else
				delete #temp_result_set
				where reference_code < @sRefLowerBound

			if (@sRefUpperBound > '')
	    		    if ((select isnumeric(@sRefUpperBound)) = 1)  --Case reference code is numeric
				delete #temp_result_set
				where reference_code > cast(@sRefUpperBound as int)
			    else
				delete #temp_result_set
				where reference_code > @sRefUpperBound

			--Populate the reference_type
			update #temp_result_set
			set reference_type = r.reference_type
			from glref r
			where #temp_result_set.reference_code = r.reference_code

			--Build a sql to get the result from #temp_result_set table
			select @sSQL = 'select * ' +
					' from #temp_result_set t' + 
					' where ' + @sSQL_Result_Where

			exec ( @sSQL )
		End
		Else
		Begin
			SELECT co.company_name, co.company_id, e.guid, e.account_code, 
		 		e.account_description, e.reference_code, e.reference_description, 
		 		e.modified_dt, e.active_dt, e.inactive_dt, g.currency_code, 
		 		g.account_type, getdate() AS system_date 
            		FROM epcoa e, glco co, #temp_glchart g 
            		WHERE  	g.account_code = e.account_code and
				((@iActiveFlag = 0 and e.inactive_dt <= @sAsOfDate) or	-- Case of inactive
				 (@iActiveFlag = 1 and (e.inactive_dt is null or e.inactive_dt > @sAsOfDate) and
					(e.active_dt is null or e.active_dt <= @sAsOfDate)) or	--Case of Active
				 (@iActiveFlag = 2)) 		--Case of Both
			UNION
			SELECT co.company_name, co.company_id, e.guid, e.account_code, 
		 		e.account_description, e.reference_code, e.reference_description, 
		 		e.modified_dt, e.active_dt, e.inactive_dt, "", 
		 		"", getdate() AS system_date 
            		FROM epcoa e, glco co
            		WHERE  	(e.deleted_dt is not null  or 
				 e.send_inactive_flg = 1)
				order by e.inactive_dt, e.account_code
		End
		RETURN
	End


	--Set all records that are not change to not modified flag
	--Note: we are not dealing any records that are not modified
	update #temp_glchart
	set modified_flg = 1
	From epcoa e
	Where 	#temp_glchart.account_code = e.account_code and
		#temp_glchart.modified_dt = e.modified_dt
	
	--Update modified_dt
	update epcoa
	set modified_dt = g.modified_dt
	from #temp_glchart g
	where 	g.account_code = epcoa.account_code and
		g.modified_flg = 0

	--Copy all records from temp_glchart to epcoa with no reference code
	insert into epcoa 
		(guid, account_code, account_description, active_dt, inactive_dt, 
		 modified_dt)
	select newid(), g.account_code, g.account_description, g.active_dt, g.inactive_dt, 
		g.modified_dt
	from #temp_glchart g
	where g.modified_flg = 0 and
		g.account_code not in
		(select account_code from epcoa 
		 where 	epcoa.account_code = g.account_code and
			epcoa.reference_code is null and
			epcoa.deleted_dt is null)

	--Set account to inactive if inactive flag is on
	update epcoa
	set inactive_dt = getdate()
	from #temp_glchart g
	where 	g.account_code = epcoa.account_code and	
		g.seg1_code like @sSeg1Mask and
		g.seg2_code like @sSeg2Mask and
		g.seg3_code like @sSeg3Mask and
		g.seg4_code like @sSeg4Mask and
		g.inactive_flag = 1 and  
		g.modified_flg = 0 and
		( epcoa.inactive_dt is null or
		  epcoa.inactive_dt > getdate())	

	--Note: At this point all the record in ep_temp_glref_acct_type are sorted in the order of
	-- reference_flag which are Excluded(1), Required(3), Optional(4)

	--Get the sequential ID from from ep_temp_glref_acct_type  
	select @iSeqId = max(seq_id) 
	from ep_temp_glref_acct_type

	--Goes through the while loop with lowest priority to the highest priority.
	While (@iSeqId is not Null)
	Begin
		select 	@iRefFlag = reference_flag,
			@sAccountMask = account_mask,
			@sRefType = reference_type 
		from 	ep_temp_glref_acct_type 
		where 	seq_id = @iSeqId

		--The following codes will manipulate the account mask
		--Get the string length of all 4 segments
		select @iSeg1Len = isnull((select len(max(seg_code)) from glseg1), 0)
		select @iSeg2Len = isnull((select len(max(seg_code)) from glseg2), 0)
		select @iSeg3Len = isnull((select len(max(seg_code)) from glseg3), 0)
		select @iSeg4Len = isnull((select len(max(seg_code)) from glseg4), 0)

		IF ((@iSeg1Len  = 0) AND (@iSeg2Len = 0) AND (@iSeg3Len = 0) AND (@iSeg4Len = 0))
		Begin
			--Don't do any thing b/c Chart Of account has not set up
			Return
		End

		--Initialize all the segment mask.  Note: all the segment does not allow null.
		--If the segment is not used, it get set to ''.
		select 	@sSeg2Mask = '',
			@sSeg3Mask = '',
			@sSeg4Mask = ''
	

		--Parse the mask of the first segment and replace all '_' with '%' to do the where clause later
		select @sSeg1Mask = LEFT(@sAccountMask, @iSeg1Len)
		select @sSeg1Mask = REPLACE(@sSeg1Mask, '_','%')
		select @sAccountMask = RIGHT(@sAccountMask, LEN(@sAccountMask) - @iSeg1Len)

		if (@iSeg2Len > 0) 
		Begin
			--Parse the mask of the second segment and replace all '_' with '%' 
			--to do the where clause later
			select @sSeg2Mask = LEFT(@sAccountMask, @iSeg2Len)
			select @sSeg2Mask = REPLACE(@sSeg2Mask, '_','%')
			select @sAccountMask = RIGHT(@sAccountMask, LEN(@sAccountMask) - @iSeg2Len)
		End

		if (@iSeg3Len > 0) 
		Begin
			--Parse the mask of the third segment and replace all '_' with '%' 
			--to do the where clause later
			select @sSeg3Mask = LEFT(@sAccountMask, @iSeg3Len)
			select @sSeg3Mask = REPLACE(@sSeg3Mask, '_','%')
			select @sAccountMask = RIGHT(@sAccountMask, LEN(@sAccountMask) - @iSeg3Len)
		End

		if (@iSeg4Len > 0) 
		Begin
			--Parse the mask of the fourth segment and replace all '_' with '%' 
			--to do the where clause later
			select @sSeg4Mask = LEFT(@sAccountMask, @iSeg4Len)
			select @sSeg4Mask = REPLACE(@sSeg4Mask, '_','%')
			select @sAccountMask = RIGHT(@sAccountMask, LEN(@sAccountMask) - @iSeg4Len)
		End

		Begin Transaction
		if (@iRefFlag = 4) --Case of Optional
		Begin 
			--Update epcoa that has no reference code
			update epcoa
			set 	account_description = g.account_description,
				active_dt = g.active_dt,
				inactive_dt = g.inactive_dt
			from #temp_glchart g
			where 	epcoa.account_code = g.account_code and
				epcoa.reference_code is null and 
				g.seg1_code like @sSeg1Mask and
				g.seg2_code like @sSeg2Mask and
				g.seg3_code like @sSeg3Mask and
				g.seg4_code like @sSeg4Mask  and
				g.modified_flg = 0  and 
				epcoa.deleted_dt is null	
				
			--Update epcoa that has reference code
			update epcoa
			set 	account_description = g.account_description,
				active_dt = g.active_dt,
				inactive_dt = g.inactive_dt
			from #temp_glchart g, glref r
			where 	epcoa.account_code = g.account_code and
				epcoa.reference_code = r.reference_code and 
				r.reference_type = @sRefType and
				g.seg1_code like @sSeg1Mask and
				g.seg2_code like @sSeg2Mask and
				g.seg3_code like @sSeg3Mask and
				g.seg4_code like @sSeg4Mask and 
				g.modified_flg = 0  and 
				epcoa.deleted_dt is null				

			--insert the account that noe exist in epcoa
			insert into epcoa 
				(guid, account_code, account_description, active_dt, inactive_dt, 
				reference_code, reference_description, modified_dt)
			select newid(), g.account_code, g.account_description, g.active_dt, 
				g.inactive_dt, r.reference_code, r.description, g.modified_dt
			from #temp_glchart g, glref r
			where 	r.reference_type = @sRefType and
				g.seg1_code like @sSeg1Mask and
				g.seg2_code like @sSeg2Mask and
				g.seg3_code like @sSeg3Mask and
				g.seg4_code like @sSeg4Mask and
				g.modified_flg = 0  and 
				g.account_code not in 
				( select account_code
				  from epcoa
				  where	epcoa.account_code = g.account_code and
					epcoa.reference_code = r.reference_code and
					epcoa.deleted_dt is null)

			--Set account to inactive if inactive flag is on
			update epcoa
			set inactive_dt = getdate()
			from #temp_glchart g, glref r
			where 	epcoa.account_code = g.account_code and	
				g.seg1_code like @sSeg1Mask and
				g.seg2_code like @sSeg2Mask and
				g.seg3_code like @sSeg3Mask and
				g.seg4_code like @sSeg4Mask and
				g.modified_flg = 0  and 
				(epcoa.reference_code is null or
				 (epcoa.reference_code = r.reference_code and
				  r.reference_type = @sRefType )) and
				(g.inactive_flag = 1 or (r.status_flag = 1 and epcoa.reference_code = r.reference_code)) and 
				( epcoa.inactive_dt is null or epcoa.inactive_dt > getdate()) and 
				epcoa.deleted_dt is null		

		End
		Else if (@iRefFlag = 3) --Case of Required
		Begin
			--Set account with no reference to inactive
			Update epcoa
			set 	inactive_dt = getdate()	
			from #temp_glchart g
			where 	epcoa.account_code = g.account_code and
				epcoa.reference_code is null and	
				g.seg1_code like @sSeg1Mask and
				g.seg2_code like @sSeg2Mask and
				g.seg3_code like @sSeg3Mask and
				g.seg4_code like @sSeg4Mask  and 
				g.modified_flg = 0  and 
				epcoa.deleted_dt is null		

			--update account with reference code
			update epcoa
			set	account_description = g.account_description,
				inactive_dt = g.inactive_dt,
				active_dt = g.active_dt,
				reference_description = r.description
			from #temp_glchart g, glref r
			where 	epcoa.account_code = g.account_code and
				epcoa.reference_code = r.reference_code and
				r.reference_type = @sRefType and
				g.seg1_code like @sSeg1Mask and
				g.seg2_code like @sSeg2Mask and
				g.seg3_code like @sSeg3Mask and
				g.seg4_code like @sSeg4Mask  and 
				g.modified_flg = 0  and 
				epcoa.deleted_dt is null		
			
			--Copy all the posible combination of #temp_glchart that
			--has the same segments and glref into epcoa.
			insert into epcoa 
				(guid, account_code, account_description, active_dt, inactive_dt, 
				reference_code,  reference_description, modified_dt)
			select newid(), g.account_code, g.account_description, g.active_dt, 
				g.inactive_dt, r.reference_code, r.description, g.modified_dt
			from #temp_glchart g, glref r
			where 	r.reference_type = @sRefType and
				g.seg1_code like @sSeg1Mask and
				g.seg2_code like @sSeg2Mask and
				g.seg3_code like @sSeg3Mask and
				g.seg4_code like @sSeg4Mask and
				g.modified_flg = 0  and 
				g.account_code not in 
					(select account_code from epcoa 
					 where	epcoa.account_code = g.account_code and
						epcoa.reference_code = r.reference_code and
						epcoa.deleted_dt is null)

			--Set account to inactive if inactive flag is on
			update epcoa
			set inactive_dt = getdate()
			from #temp_glchart g, glref r
			where 	epcoa.account_code = g.account_code and	
				g.seg1_code like @sSeg1Mask and
				g.seg2_code like @sSeg2Mask and
				g.seg3_code like @sSeg3Mask and
				g.seg4_code like @sSeg4Mask and
				g.modified_flg = 0  and 
				(epcoa.reference_code is null or
				 (epcoa.reference_code = r.reference_code and
				  r.reference_type = @sRefType )) and
				(g.inactive_flag = 1 or (r.status_flag = 1 and epcoa.reference_code = r.reference_code)) and 
				( epcoa.inactive_dt is null or
				  epcoa.inactive_dt > getdate()) and
				epcoa.deleted_dt is null		

		End
		Else if (@iRefFlag = 1) --Case of Excluded
		Begin
			--Set account with reference to inactive
			Update epcoa
			set 	inactive_dt = getdate()
			from #temp_glchart g, glref r
			where 	epcoa.account_code = g.account_code and
				epcoa.reference_code = r.reference_code and
				r.reference_type = @sRefType and
				g.seg1_code like @sSeg1Mask and
				g.seg2_code like @sSeg2Mask and
				g.seg3_code like @sSeg3Mask and
				g.seg4_code like @sSeg4Mask and 
				g.modified_flg = 0  and 
				epcoa.deleted_dt is null		

			--Set account with no reference to active
			update epcoa
			set inactive_dt = g.inactive_dt
			from #temp_glchart g
			where 	epcoa.account_code = g.account_code and
				epcoa.reference_code is null and
				g.seg1_code like @sSeg1Mask and
				g.seg2_code like @sSeg2Mask and
				g.seg3_code like @sSeg3Mask and
				g.seg4_code like @sSeg4Mask and 
				g.modified_flg = 0  and 
				epcoa.deleted_dt is null		

			--Copy all the posible combination of #temp_glchart that
			--has the same segments and glref into epcoa.
			insert into epcoa 
				(guid, account_code, account_description, active_dt, inactive_dt, 
				reference_code, reference_description, modified_dt)
			select newid(), g.account_code, g.account_description, g.active_dt, 
				getdate(), r.reference_code, r.description, g.modified_dt
			from #temp_glchart g, glref r
			where 	r.reference_type = @sRefType and
				g.seg1_code like @sSeg1Mask and
				g.seg2_code like @sSeg2Mask and
				g.seg3_code like @sSeg3Mask and
				g.seg4_code like @sSeg4Mask and
				g.modified_flg = 0  and 
				g.account_code not in 
					(select epcoa.account_code from epcoa 
					 where	epcoa.account_code = g.account_code and
						epcoa.reference_code = r.reference_code and
						epcoa.deleted_dt is null)

			--Set account to inactive if inactive flag is on
			update epcoa
			set inactive_dt = getdate()
			from #temp_glchart g, glref r
			where 	epcoa.account_code = g.account_code and	
				g.seg1_code like @sSeg1Mask and
				g.seg2_code like @sSeg2Mask and
				g.seg3_code like @sSeg3Mask and
				g.seg4_code like @sSeg4Mask and
				g.modified_flg = 0  and 
				(epcoa.reference_code is null or
				 (epcoa.reference_code = r.reference_code and
				  r.reference_type = @sRefType )) and
				(g.inactive_flag = 1 or (r.status_flag = 1 and epcoa.reference_code = r.reference_code)) and 
				( epcoa.inactive_dt is null or
				  epcoa.inactive_dt > getdate()) and
				epcoa.deleted_dt is null		
		End

		Commit Transaction
		--Get the sequential ID from from ep_temp_glref_acct_type  
		select @iSeqId = max(seq_id) 
		from ep_temp_glref_acct_type
		where 	seq_id < @iSeqId
	End --End While loop

	--Set all inactive account to inactive
	update epcoa
	set inactive_dt = getdate()
	from #temp_glchart g
	where 	epcoa.account_code = g.account_code and
		g.inactive_flag = 1 and
		g.modified_flg = 0  and 
		( epcoa.inactive_dt >= getdate() or
		  epcoa.inactive_dt is null )

	--Set all inactive reference to inactive
	update epcoa
	set inactive_dt = getdate()
	from glref r, #temp_glchart g
	where 	epcoa.reference_code = r.reference_code and
		epcoa.account_code = g.account_code and 
		g.modified_flg = 0  and 
		r.status_flag = 1 and
		( epcoa.inactive_dt >= getdate() or
		  epcoa.inactive_dt is null )

	if  (@sSQL_Result_Where > '')
	Begin
		--Insert into the temp table
		Insert into #temp_result_set( company_name, company_id,	guid, account_code,
			account_description, reference_code, reference_description, 
			modified_dt, active_dt, inactive_dt, currency_code, account_type,
			system_date)
		SELECT co.company_name, co.company_id, e.guid, e.account_code, 
	 		e.account_description, e.reference_code, e.reference_description, 
	 		e.modified_dt, e.active_dt, e.inactive_dt, g.currency_code, 
	 		g.account_type, getdate() AS system_date 
     		FROM epcoa e, glco co, #temp_glchart g 
     		WHERE  	g.account_code = e.account_code and
			((@iActiveFlag = 0 and e.inactive_dt <= @sAsOfDate) or	-- Case of inactive
			 (@iActiveFlag = 1 and (e.inactive_dt is null or e.inactive_dt > @sAsOfDate) and
				(e.active_dt is null or e.active_dt <= @sAsOfDate)) or	--Case of Active
			 (@iActiveFlag = 2)) 		--Case of Both
		UNION
		SELECT co.company_name, co.company_id, e.guid, e.account_code, 
		 	e.account_description, e.reference_code, e.reference_description, 
	 		e.modified_dt, e.active_dt, e.inactive_dt, "", 
	 		"", getdate() AS system_date 
     		FROM epcoa e, glco co
     		WHERE  	(e.deleted_dt is not null  or 
			 e.send_inactive_flg = 1)
		order by e.inactive_dt, e.account_code


		--Clean up the #temp_result_set
		if (@sRefLowerBound > '')
			delete #temp_result_set
			where reference_code < @sRefLowerBound

		if (@sRefUpperBound > '')
			delete #temp_result_set
			where reference_code > @sRefUpperBound

		--Populate the reference_type
		update #temp_result_set
		set reference_type = r.reference_type
		from glref r
		where #temp_result_set.reference_code = r.reference_code

		--Build a sql to get the result from #temp_result_set table
		select @sSQL = 'select * ' +
				' from #temp_result_set t' + 
				' where ' + @sSQL_Result_Where
		exec (@sSQL)
	End
	Else
	Begin
		SELECT co.company_name, co.company_id, e.guid, e.account_code, 
	 		e.account_description, e.reference_code, e.reference_description, 
	 		e.modified_dt, e.active_dt, e.inactive_dt, g.currency_code, 
	 		g.account_type, getdate() AS system_date 
     		FROM epcoa e, glco co, #temp_glchart g 
     		WHERE  	g.account_code = e.account_code and
			((@iActiveFlag = 0 and e.inactive_dt <= @sAsOfDate) or	-- Case of inactive
			 (@iActiveFlag = 1 and (e.inactive_dt is null or e.inactive_dt > @sAsOfDate) and
				(e.active_dt is null or e.active_dt <= @sAsOfDate)) or	--Case of Active
			 (@iActiveFlag = 2)) 		--Case of Both
		UNION
		SELECT co.company_name, co.company_id, e.guid, e.account_code, 
	 		e.account_description, e.reference_code, e.reference_description, 
	 		e.modified_dt, e.active_dt, e.inactive_dt, "", 
	 		"", getdate() AS system_date 
     		FROM epcoa e, glco co
     		WHERE  	(e.deleted_dt is not null  or 
				 e.send_inactive_flg = 1)
		order by e.inactive_dt, e.account_code
	End

END


GO
GRANT EXECUTE ON  [dbo].[ep_coa_process] TO [public]
GO
