SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create proc [dbo].[fs_update_forecast_history]
		@year_quarter int = 0,
		@part_no varchar(30), 
		@location varchar(10) = '',
		@bucket int,
		@value decimal(20, 8) = 0,
		@promoid int = 0,
		@inactive_ind int = 0,
		@xref_part varchar(30) = '',
		@online_call int = 1
as 
	DECLARE	@partid int,
		@locid int,
		@timeid int

	declare @old_cross_ref_PRODUCTID int,
		@new_cross_ref_PRODUCTID int,
		@old_forecast_flag int,
		@old_xref_part varchar(30),
		@ia_part varchar(30)

	if @bucket > 0 
        begin
		SELECT @partid = ISNULL((SELECT PRODUCTID FROM EFORECAST_PRODUCT WHERE PART_NO = @part_no), -1)
		SELECT @locid = ISNULL((SELECT LOCATIONID FROM EFORECAST_LOCATION WHERE LOCATION = @location), -1)
		SELECT @timeid = MIN(TIMEID) - 1 + @bucket FROM EFORECAST_TIME WHERE YEAR_QUARTER = @year_quarter

		IF EXISTS (SELECT 1 FROM EFORECAST_SALESALL WHERE TIMEID = @timeid AND PRODUCTID = @partid AND LOCATIONID = @locid)
		BEGIN
			UPDATE EFORECAST_SALESALL 
			SET UNITS = GROSS_SOLD_QTY - RETURN_QTY + @value,		-- mls 3/6/07 SCR 37602
				ADJUSTMENT_QTY = @value,
				PROMOID = @promoid
				WHERE TIMEID = @timeid 
				AND PRODUCTID = @partid 
				AND LOCATIONID = @locid 
		END
		ELSE 
		BEGIN
			INSERT INTO EFORECAST_SALESALL 
				(TIMEID, PRODUCTID, LOCATIONID, PROMOID, UNITS, GROSS_SOLD_QTY, RETURN_QTY, ADJUSTMENT_QTY)
			 VALUES
			 	(@timeid, @partid, @locid, @promoid, @value, 0, 0, @value)
		END

		if @online_call = 1
	  		select 1, ''
		return
	END

	if @bucket = -1	-- cross reference data
	begin
		SELECT @partid = ISNULL((SELECT PRODUCTID FROM EFORECAST_PRODUCT WHERE PART_NO = @part_no), -1)

		if @partid = -1
		begin
			if @online_call = 1 	select -2, 'Invalid Product ID'
			return -2
		end

		select @inactive_ind = isnull(@inactive_ind,0)
  		select @xref_part = isnull(@xref_part,'')

		select @old_cross_ref_PRODUCTID = 0, @new_cross_ref_PRODUCTID = 0	

		select @old_forecast_flag = isnull(FORECAST_FLAG,0)  ,
			@old_xref_part = case when isnull(FORECAST_FLAG,0) = 0 then '' 
			else isnull(CROSS_REF_PART_NO,'') end	-- mls 4/19/01 SCR 26758
		from EFORECAST_PRODUCT (nolock)
		where PRODUCTID = @partid

		if (@inactive_ind = 1 and @old_forecast_flag = 0) or (@old_xref_part <> @xref_part and @inactive_ind = 1)
		begin
			select @ia_part = isnull((select min(ia.PART) 
			from EFORECAST_PRODUCT ia (nolock), EFORECAST_PRODUCT cr (nolock)
			where ia.CROSS_REF_PART_NO = cr.PART and cr.PRODUCTID = @partid and ia.FORECAST_FLAG = 1),NULL)

			if @ia_part is NOT NULL
			begin
				if @online_call = 1
					select 4201, 'You cannot inactivate this item because it is a cross reference item for part: ' + @ia_part
				return 4201
			end

			if @xref_part != ''
			begin
				select @ia_part = isnull((select min(ia.PART) from EFORECAST_PRODUCT ia (nolock)
				where ia.PART = @xref_part and ia.FORECAST_FLAG = 1),NULL)
			
				if @ia_part is NOT NULL
				begin
					if @online_call = 1
						select 4201, 'You cannot cross reference this item to an inactivated part: ' + @ia_part
					return 4201
				end
			end
		end

		if @inactive_ind = 1 and (@xref_part = @part_no)
		begin
			if @online_call = 1
				select 4202, 'You cannot cross reference this item to itself.'
			return 4202
		end

		if @inactive_ind = 0	select @xref_part = ''

		create table #temp ( LOCATIONID int , TIMEID int , qty real ) 
		insert 	#temp
		select 	LOCATIONID , TIMEID , UNITS
		from 	EFORECAST_SALESALL 
		where	PRODUCTID = @partid and abs ( isnull (UNITS , 0 ) ) > 0 

		if @old_xref_part <> ''									-- mls 4/19/01 SCR 26758
		begin
			select @old_cross_ref_PRODUCTID = isnull(PRODUCTID,0) 
			from 	EFORECAST_PRODUCT
			where	PART  = 	@old_xref_part 
		end

		if (@old_xref_part <>  @xref_part ) and @xref_part <> ''				-- mls 4/19/01 SCR 26758
		begin
			select 	@new_cross_ref_PRODUCTID = PRODUCTID
			from 	EFORECAST_PRODUCT
			where	PART = @xref_part
		end

		if ( @inactive_ind  <> @old_forecast_flag ) or ( @xref_part  <> @old_xref_part )		-- mls 4/19/01 SCR 26758
		begin
			BEGIN TRAN
			update 	EFORECAST_PRODUCT
			set	FORECAST_FLAG = @inactive_ind, 
				CROSS_REF_PART_NO = case when @inactive_ind = 0 then NULL else @xref_part end 
			where	PRODUCTID = 	@partid

			if @@error <> 0 
			begin
				rollback tran
				if @online_call = 1 	select 134, 'Error 134'
				return 134
			end

		




			if @new_cross_ref_PRODUCTID > 0
			begin
				update EFORECAST_SALESALL 
				set ADJUSTMENT_QTY = isnull ( ADJUSTMENT_QTY , 0 ) +  qty , 
				UNITS = isnull ( UNITS  , 0 ) +  qty
				from EFORECAST_SALESALL , #temp
				where EFORECAST_SALESALL.PRODUCTID = @new_cross_ref_PRODUCTID  and
				EFORECAST_SALESALL.LOCATIONID = #temp.LOCATIONID and
				EFORECAST_SALESALL.TIMEID = #temp.TIMEID 
			
				if @@error <> 0 
				begin
					rollback tran
					if @online_call = 1	select 1349, 'Error 1349'
					return 1349
				end
			
				insert EFORECAST_SALESALL ( TIMEID,  PRODUCTID , LOCATIONID , PROMOID , UNITS , 
				PRICE , COST , REVENUE , PROFIT, GROSS_SOLD_QTY, RETURN_QTY , ADJUSTMENT_QTY )
				select TIMEID , @new_cross_ref_PRODUCTID  , 
				LOCATIONID , 0 , qty , 0 , 0 , 0, 0, 0, 0,   qty
				from #temp
				where not exists ( select * from EFORECAST_SALESALL s 
				where s.PRODUCTID = @new_cross_ref_PRODUCTID  and s.TIMEID = #temp.TIMEID and
				s.LOCATIONID = #temp.LOCATIONID)
			 
				if @@error <> 0 
				begin
					rollback tran
					if @online_call = 1	select 1350, 'Error 1350'
					return 1350
				end
			end

			if @old_cross_ref_PRODUCTID > 0
			begin
				update EFORECAST_SALESALL 
				set ADJUSTMENT_QTY = isnull ( ADJUSTMENT_QTY , 0 ) - qty , 
					UNITS = isnull ( UNITS  , 0 ) - qty
				from EFORECAST_SALESALL , #temp
				where EFORECAST_SALESALL.PRODUCTID = @old_cross_ref_PRODUCTID  and
					EFORECAST_SALESALL.LOCATIONID = #temp.LOCATIONID and
					EFORECAST_SALESALL.TIMEID = #temp.TIMEID 
			
				if @@error <> 0 
				begin
					rollback tran
					if @online_call = 1	select 1334, 'Error 1334'
					return 1334
				end
			end
			COMMIT TRAN
		end

		if @online_call = 1
	  		select 1, ''
		return 1
	end
	if @online_call = 1
	  select -1, 'invalid bucket'
GO
GRANT EXECUTE ON  [dbo].[fs_update_forecast_history] TO [public]
GO
