SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amdisposalreport_sp] 
(
 @book_code 		smBookCode,  
 @period_start 		int,   --mod002
 @period_end 		int,  --mod002
 @debug_level 		smDebugLevel = 0  
)
AS
DECLARE  
 @rowcount smCounter,  @return_status smErrorCode,  @co_asset_id1 smSurrogateKey, 
 @co_asset_id2 smSurrogateKey,  @is_imported smLogical,  @co_asset_id smSurrogateKey, 
 @co_asset_book_id smSurrogateKey,  @asset_first_num smControlNumber,  @asset_secnd_num smControlNumber, 
 @cost smMoneyZero,  @accum_depr smMoneyZero,  @value smMoneyZero,  @asset_total_val smMoneyZero, 
 @depr_total_val smMoneyZero,  @addition_val smMoneyZero,  @revaluation_val smMoneyZero, 
 @improvement_val smMoneyZero,  @adjustment_val smMoneyZero,  @impairment_val smMoneyZero, 
 @disposition_val smMoneyZero,  @depreciation_val smMoneyZero,  @profile_date smApplyDate, 
 @fiscal_period_start smApplyDate,  @fiscal_period_end smApplyDate,  @total_string smStringText,
 @open_wdv smMoneyZero,
 @close_wdv smMoneyZero,
 @cost_open_bal  smMoneyZero,
 @cost_close_bal smMoneyZero,
 @depr_open_bal  smMoneyZero,
 @depr_close_bal smMoneyZero,
 @cost_additions smMoneyZero,
 @cost_disposals smMoneyZero,
 @original_cost smMoneyZero, 
 @company_id	 smCompanyID ,
 @ytd_depr_exp	 smMoneyZero,
 @fin_yr_start   int,
 @fin_yr_start_date smApplyDate,
 @proceeds 		float,
 @disposition_date  smApplyDate,
 @company_name	varchar(30),
 @save_fiscal_period_end smApplyDate,		
 @curr_precision int,
 @rounding_factor float,
 @result	smErrorCode

EXEC	@result = amGetCurrencyPrecision_sp
					@curr_precision		OUTPUT,
					@rounding_factor 	OUTPUT


SELECT @company_id = company_id,
		@company_name = company_name
FROM   glco


--mod002
select @profile_date = DATEADD(dd,(@period_start -(SIGN(@period_start)*693596)),'19000101')	
select @fiscal_period_start = DATEADD(dd,(@period_start -(SIGN(@period_start)*693596)),'19000101')	
select @fiscal_period_end = DATEADD(dd,(@period_end -(SIGN(@period_end)*693596)),'19000101')		
select @save_fiscal_period_end = DATEADD(dd,(@period_end -(SIGN(@period_end)*693596)),'19000101')	

                  

CREATE table #amfar
(
 asset_ctrl_num 	char(17) NULL,  
 co_asset_id 		int NULL,  
 asset_description 	varchar(40) NULL, 

 open_wdv 		float NULL,  
 cost_open_bal  	float NULL,
 cost_additions 	float NULL,  
 cost_disposals 	float NULL, 
 cost_close_bal 	float NULL,

 depr_open_bal  	float NULL,
 prd_depr_exp   	float NULL,
 depr_disposals 	float NULL,
 depr_close_bal 	float NULL,
 close_wdv      	float NULL,

 proceeds			float NULL,
 profit				float NULL,
 loss				float NULL,
 prd_accum_depr		float NULL,

 acquisition_date 	datetime NULL,
 in_service_date 	datetime NULL,
 disposition_date	datetime NULL,
 asset_type_code 	varchar(8) NULL,
 type_description 	varchar(40) NULL,

 location_code		varchar(8) NULL,
 location_description varchar(40) NULL,
 org_id		     varchar(30) NULL,
 region_id	     varchar(30) NULL	
)

                         

INSERT #amfar (co_asset_id, open_wdv, cost_open_bal,
				cost_additions, cost_disposals, cost_close_bal, depr_open_bal, 
				prd_depr_exp, depr_disposals, depr_close_bal, close_wdv, 
				proceeds, profit, loss, org_id, region_id)
SELECT  co_asset_id,  0.0,  0.0,  
		0.0,  0.0,  0.0,  0.0,  
		0.0,  0.0, revised_accum_depr = case when b.trx_type = '60' then abs(b.revised_accum_depr) end,
		revised_cost = case when b.trx_type = '60' then b.revised_cost end, 
		proceeds,  gain_loss = case when gain_loss < 0 then abs(gain_loss) else 0.00 end, 	--mod004
		gain_loss = case when gain_loss > 0 then abs(gain_loss) else 0.00 end,"",""		--mod004
FROM amastbk a, amacthst b
WHERE book_code = @book_code 
AND a.co_asset_book_id = b.co_asset_book_id							--mod004
AND b.trx_type = '60'										--mod004
AND co_asset_id IN (SELECT co_asset_id
					FROM #amassets ) 


SELECT co_asset_id,  co_asset_book_id, proceeds
INTO #counter1
FROM amastbk
WHERE book_code = @book_code 
AND co_asset_id IN (SELECT co_asset_id
					FROM #amassets ) 

					
WHILE 1=1
BEGIN  
  SET ROWCOUNT 1 
 
  SELECT @co_asset_id = co_asset_id,  
  		@co_asset_book_id = co_asset_book_id,
  		@proceeds = proceeds 
  FROM #counter1 

  IF @@rowcount = 0 
  BEGIN 
    SET ROWCOUNT 0 
    BREAK 
  END    
  
  SELECT @original_cost = original_cost, 
  		 @disposition_date = ISNULL(disposition_date,'')
  FROM amasset
  WHERE co_asset_id = @co_asset_id
  
  /* make the fiscal period end the disposition date less one day */
  SELECT @fiscal_period_end = DATEADD(dd,-1,@disposition_date)


  EXEC @return_status = amGetPrfRep_sp @co_asset_book_id,  @profile_date, @curr_precision, 
  						@cost OUTPUT,  @accum_depr OUTPUT 
  /* account_type 0 */
  BEGIN   
    SELECT  @asset_total_val = 0.0,  
			@addition_val = 0.0,  
			@revaluation_val = 0.0,  
			@improvement_val = 0.0, 
 			@adjustment_val = 0.0,  
			@impairment_val = 0.0,  
			@disposition_val = 0.0,  
			@depreciation_val = 0.0,
			@cost_additions = 0.0,
			@cost_disposals = 0.0

    SELECT @asset_total_val = isnull(@asset_total_val,0.0) + isnull(@cost,0.0)   

	EXEC @return_status = amGetValueRep_sp 
		 @co_asset_book_id,  0,  @fiscal_period_start,  @fiscal_period_end,  10, @curr_precision, 
		 	@value OUTPUT 
    IF ( @return_status != 0 )  
		RETURN @return_status 
    SELECT @addition_val = isnull(@value,0.0) 
    SELECT @asset_total_val = @asset_total_val + isnull(@value,0.0)   


	EXEC @return_status = amGetValueRep_sp  @co_asset_book_id,  0,  @fiscal_period_start,  @fiscal_period_end,  40, 
		@curr_precision, @value output 
    IF ( @return_status != 0 )  RETURN @return_status 
    SELECT @revaluation_val = isnull(@value,0.0) 
    SELECT @asset_total_val = @asset_total_val + isnull(@value,0.0)   

	EXEC @return_status = amGetValueRep_sp 
			 @co_asset_book_id,  0,  @fiscal_period_start,  @fiscal_period_end,  20, @curr_precision, @value output 
    IF ( @return_status != 0 )  RETURN @return_status 
    SELECT @improvement_val = isnull(@value,0.0) 
    SELECT @asset_total_val = @asset_total_val + isnull(@value,0.0)   

	EXEC @return_status = amGetValueRep_sp 
		 @co_asset_book_id,  0,  @fiscal_period_start,  @fiscal_period_end,  42, @curr_precision, @value output 
    IF ( @return_status != 0 )  RETURN @return_status 
    SELECT @adjustment_val = isnull(@value,0.0) 
    SELECT @asset_total_val = @asset_total_val + isnull(@value,0.0)   

	EXEC @return_status = amGetValueRep_sp 
		 @co_asset_book_id,  0,  @fiscal_period_start,  @fiscal_period_end,  41, @curr_precision, @value output 
    IF ( @return_status != 0 )  RETURN @return_status 
    SELECT @impairment_val = isnull(@value,0.0) 
    SELECT @asset_total_val = @asset_total_val + isnull(@value,0.0)   

	EXEC @return_status = amGetValueRep_sp 
		 @co_asset_book_id,  0,  @fiscal_period_start,  @fiscal_period_end,  30, @curr_precision, @value output 
    IF ( @return_status != 0 )  RETURN @return_status 
    SELECT @disposition_val = isnull(@value,0.0) 
    SELECT @asset_total_val = @asset_total_val + isnull(@value,0.0)   

	EXEC @return_status = amGetValueRep_sp 
		 @co_asset_book_id,  0,  @fiscal_period_start,  @fiscal_period_end,  50, @curr_precision, @value output 
    IF ( @return_status != 0 )  RETURN @return_status 
    SELECT @depreciation_val = isnull(@value,0.0) 
    SELECT @asset_total_val = @asset_total_val + isnull(@value,0.0)   

	EXEC @return_status = amGetValueRep_sp 
		 @co_asset_book_id,  0,  @fiscal_period_start,  @fiscal_period_end,  60,@curr_precision,  @value output 
    IF ( @return_status != 0 )  RETURN @return_status 
    SELECT @depreciation_val = @value + isnull(@value, 0.0) 
    SELECT @asset_total_val = @asset_total_val + isnull(@value, 0.0)   

	EXEC @return_status = amGetValueRep_sp 
		 @co_asset_book_id,  0,  @fiscal_period_start,  @fiscal_period_end,  70, @curr_precision, @value output 
    IF ( @return_status != 0 )  RETURN @return_status 

    SELECT @disposition_val = @disposition_val + isnull(@value,0.0) 
    SELECT @asset_total_val = @asset_total_val + isnull(@value,0.0)  
	
    IF ( @return_status != 0 )  RETURN @return_status 
	
	/* mod001 */	
	IF @addition_val > 0
		SELECT @cost_additions = @cost_additions + @addition_val
	ELSE
		SELECT @cost_disposals = @cost_disposals + @addition_val

	IF @revaluation_val > 0
		SELECT @cost_additions = @cost_additions + @revaluation_val
	ELSE
		SELECT @cost_disposals = @cost_disposals + @revaluation_val
		
	IF @improvement_val > 0 
		SELECT @cost_additions = @cost_additions + @improvement_val
	ELSE
		SELECT @cost_disposals = @cost_disposals + @improvement_val

	IF @impairment_val > 0
		SELECT @cost_additions = @cost_additions + @impairment_val
	ELSE
		SELECT @cost_disposals = @cost_disposals + @impairment_val
			
	IF @disposition_val > 0
		SELECT @cost_additions = @cost_additions + @disposition_val
	ELSE
		SELECT @cost_disposals = @cost_disposals + @disposition_val
		
				
	SELECT @cost_open_bal = ISNULL(@cost,0.0),
		   @cost_close_bal = ISNULL(@asset_total_val,0.0)
	
	UPDATE #amfar
	SET cost_open_bal = @cost_open_bal,
		cost_additions = @cost_additions,
		cost_disposals = @cost_disposals,
		cost_close_bal = @cost_close_bal
	WHERE co_asset_id = @co_asset_id
	SELECT @return_status = @@error
	
	IF ( @return_status != 0 ) RETURN @return_status
  END  
  /*---------------------------- account_type 1--------------------------------- */  
  BEGIN   
    SELECT  @depr_total_val = 0.0, 
 			@addition_val = 0.0,  @revaluation_val = 0.0,  @improvement_val = 0.0,  @adjustment_val = 0.0, 
			 @impairment_val = 0.0,  @disposition_val = 0.0,  @depreciation_val = 0.0 

  EXEC @return_status = amGetValueRep_sp  @co_asset_book_id,  1,  @fiscal_period_start, 
 @fiscal_period_end,  10, @curr_precision, @value output 
    IF ( @return_status != 0 )  RETURN @return_status 

    IF isnull(@value,0.0) = 0.0 
	    SELECT @addition_val = isnull(@value,0.0) 
    ELSE 
	    SELECT @addition_val = -(isnull(@value,0.0)) 
    SELECT @depr_total_val = @depr_total_val - isnull(@value,0.0)   

	EXEC @return_status = amGetValueRep_sp 
		 @co_asset_book_id,  1,  @fiscal_period_start,  @fiscal_period_end,  40, @curr_precision, @value output 
    IF ( @return_status != 0 )  RETURN @return_status 
    IF isnull(@value,0.0) = 0.0 
	    SELECT @revaluation_val = isnull(@value,0.0) 
    ELSE 
	    SELECT @revaluation_val = -(isnull(@value,0.0)) 
    SELECT @depr_total_val = @depr_total_val - isnull(@value,0.0) 

	EXEC @return_status = amGetValueRep_sp  @co_asset_book_id,  1,  @fiscal_period_start, 
		 @fiscal_period_end,  20, @curr_precision, @value output 
    IF ( @return_status != 0 )  RETURN @return_status 
    IF isnull(@value,0.0) = 0.0 
	    SELECT @improvement_val = isnull(@value,0.0) 
    ELSE 
	    SELECT @improvement_val = -(isnull(@value,0.0)) 
    SELECT @depr_total_val = @depr_total_val - isnull(@value,0.0) 

	EXEC @return_status = amGetValueRep_sp  @co_asset_book_id,  1,  @fiscal_period_start, 
		 @fiscal_period_end,  42,@curr_precision,  @value output 
    IF ( @return_status != 0 )  RETURN @return_status 
    IF isnull(@value,0.0) = 0.0 
	    SELECT @adjustment_val = isnull(@value,0.0) 
    ELSE 
	    SELECT @adjustment_val = -(isnull(@value,0.0)) 
    SELECT @depr_total_val = @depr_total_val - isnull(@value,0.0)   
	
	EXEC @return_status = amGetValueRep_sp 
		 @co_asset_book_id,  1,  @fiscal_period_start,  @fiscal_period_end,  41, @curr_precision, @value output 
    IF ( @return_status != 0 )  RETURN @return_status 
    IF isnull(@value,0.0) = 0.0 
	    SELECT @impairment_val = isnull(@value,0.0) 
    ELSE 
	    SELECT @impairment_val = -(isnull(@value,0.0)) 
    SELECT @depr_total_val = @depr_total_val - isnull(@value,0.0) 

    EXEC @return_status = amGetValueRep_sp  @co_asset_book_id,  1,  @fiscal_period_start, 
		 @fiscal_period_end,  30, @curr_precision, @value OUTPUT 
    IF ( @return_status != 0 )  RETURN @return_status 
    IF isnull(@value,0.0) = 0.0 
	    SELECT @disposition_val = isnull(@value,0.0) 
    ELSE 
	    SELECT @disposition_val = -(isnull(@value,0.0)) 
    SELECT @depr_total_val = @depr_total_val - isnull(@value,0.0) 

    EXEC @return_status = amGetValueRep_sp  @co_asset_book_id,  1,  @fiscal_period_start, 
		 @fiscal_period_end,  50, @curr_precision, @value OUTPUT 
    IF ( @return_status != 0 )  RETURN @return_status 
    IF isnull(@value,0.0) = 0.0 
	    SELECT @depreciation_val = isnull(@value,0.0) 
    ELSE 
	    SELECT @depreciation_val = -(isnull(@value,0.0)) 
    SELECT @depr_total_val = @depr_total_val - isnull(@value,0.0) 

    EXEC @return_status = amGetValueRep_sp  @co_asset_book_id,  1,  @fiscal_period_start, 
		 @fiscal_period_end,  60, @curr_precision, @value OUTPUT 
    IF ( @return_status != 0 )  RETURN @return_status 
    IF isnull(@value,0.0) = 0.0 
	    SELECT @depreciation_val = @depreciation_val + isnull(@value,0.0) 
    ELSE 
	    SELECT @depreciation_val = @depreciation_val - (isnull(@value,0.0))

    SELECT @depr_total_val = @depr_total_val - isnull(@value,0.0) 

    EXEC @return_status = amGetValueRep_sp  @co_asset_book_id,  1,  @fiscal_period_start, 
		 @fiscal_period_end,  70, @curr_precision, @value OUTPUT 
    IF ( @return_status != 0 )  RETURN @return_status 
    IF isnull(@value, 0.0) = 0.0 
	    SELECT @disposition_val = @disposition_val + isnull(@value, 0.0) 
    ELSE 
	    SELECT @disposition_val = @disposition_val - (isnull(@value, 0.0)) 
    SELECT @depr_total_val = @depr_total_val - isnull(@value,0.0) 
 
    IF isnull(@accum_depr, 0.0) = 0.0 
	    SELECT @accum_depr = isnull(@accum_depr, 0.0) 
    ELSE 
	    SELECT @accum_depr = -(isnull(@accum_depr, 0.0))  

    SELECT  @depr_open_bal = ISNULL(@accum_depr,0.0),
    		@depr_close_bal = ISNULL(@depr_total_val,0.0) - ISNULL(@accum_depr,0.0) 

	/* gain and loss are in different columns */
	IF ( (@original_cost - (@depr_open_bal + @depreciation_val) - @proceeds)*-1 ) > 0
	BEGIN	
		UPDATE #amfar
		SET depr_open_bal = round(@depr_open_bal,2),
			prd_depr_exp = round(@depreciation_val,2),
			depr_disposals = round(@disposition_val,2),				
			--mod004 depr_close_bal = round(@depr_close_bal,2),						
			--mod004 profit = (@original_cost - (@depr_open_bal + @depreciation_val) - @proceeds)*-1,
			prd_accum_depr = round(@depr_total_val, 2)
		WHERE co_asset_id = @co_asset_id
		SELECT @return_status = @@error
	END
	ELSE
	BEGIN
		UPDATE #amfar
		SET depr_open_bal = round(@depr_open_bal,2),
			prd_depr_exp = round(@depreciation_val,2),
			depr_disposals = round(@disposition_val,2),				
			--mod004 depr_close_bal = round(@depr_close_bal,2),						
			--mod004loss = (@original_cost - (@depr_open_bal + @depreciation_val) - @proceeds)*-1,
			prd_accum_depr = round(@depr_total_val, 2)
		WHERE co_asset_id = @co_asset_id
		SELECT @return_status = @@error
	END


			
	IF ( @return_status != 0 ) RETURN @return_status



  END   
  
  SELECT @open_wdv = ISNULL(@cost, 0.0) - ISNULL(@accum_depr, 0.0)
   	 --@close_wdv = ISNULL(@asset_total_val, 0.0) - (@depr_open_bal + @depr_total_val)
  
  UPDATE #amfar
  SET open_wdv = round(@open_wdv,2)
	  --close_wdv = round(@close_wdv,2)
  WHERE co_asset_id = @co_asset_id
  SELECT @return_status = @@error
	
  IF ( @return_status != 0 ) RETURN @return_status
  
  DELETE #counter1 
  SET ROWCOUNT 0
END    

UPDATE #amfar
SET #amfar.asset_ctrl_num = ISNULL(b.asset_ctrl_num,''), 
    #amfar.asset_description = ISNULL(b.asset_description,''),
	#amfar.acquisition_date = ISNULL(b.acquisition_date,''),		
	#amfar.in_service_date = ISNULL(c.placed_in_service_date,''),
	#amfar.asset_type_code = ISNULL(b.asset_type_code,''),
	#amfar.location_code = ISNULL(b.location_code,''),
	#amfar.disposition_date = ISNULL(b.disposition_date,'')
FROM #amfar,  amasset b , amastbk c
WHERE #amfar.co_asset_id = b.co_asset_id    
	and b.co_asset_id = c.co_asset_id      

UPDATE #amfar
SET #amfar.type_description = asset_type_description
FROM #amfar, amasttyp b
WHERE #amfar.asset_type_code = b.asset_type_code

UPDATE #amfar
SET #amfar.location_description = b.location_description
FROM #amfar, amloc b
WHERe #amfar.location_code = b.location_code


UPDATE #amfar
SET #amfar.org_id = ISNULL(b.org_id,""), 
    #amfar.region_id = ISNULL(dbo.IBGetParent_fn (b.org_id),"")
FROM #amfar,  amasset b, amOrganization_vw o,region_vw r 
WHERE #amfar.co_asset_id = b.co_asset_id
AND	b.org_id			= o.org_id
AND     b.org_id 			= r.org_id 


EXEC @return_status = amGetString_sp  21,  @total_string OUTPUT

IF @return_status <> 0  RETURN @return_status  

INSERT INTO #amdisposals ( asset_type_code, type_description,
 asset_ctrl_num, asset_description	 , location_description, in_service_date ,
 disposition_date, cost_close_bal, depr_open_bal , open_wdv	   , prd_accum_depr,
 accum_depr_on_disp,
 book_value_on_disp,
 proceeds	   , profit		   , loss, org_id, region_id		   
)
SELECT distinct 	asset_type_code, type_description,
			asset_ctrl_num, asset_description, location_description, in_service_date,
			disposition_date, cost_close_bal, depr_open_bal, open_wdv, open_wdv - (close_wdv - depr_close_bal) prd_accum_depr,
			/*mod004(depr_open_bal - prd_accum_depr)*/ depr_close_bal as accum_depr_on_disp,
			/*mod004 close_wdv*/ (close_wdv - depr_close_bal)as book_value_on_disp,
			proceeds, profit, loss, org_id, region_id
	FROM  #amfar
	ORDER BY asset_type_code, asset_ctrl_num 
	

DROP TABLE #amfar
RETURN 0

GO
GRANT EXECUTE ON  [dbo].[amdisposalreport_sp] TO [public]
GO
