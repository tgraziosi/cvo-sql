SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[amFar_sp] 
(
/* mod001 - company_id is no longer a parameter in Publisher report, it will be
	overridden by selecting the company_id from amco
@company_id smCompanyID, 	*/
/* @asset_ctrl_num1 	smControlNumber,     */
/* @asset_ctrl_num2 	smControlNumber, */
/* @activity_state	smallint,  */
/* @activity_str 		varchar(16), */		/* mod001 - was activity_state, smallint */
/* @select_assets 	tinyint,	*/	/* mod001 - hard-coded in SqlPub to call all assets */
 @book_code 		smBookCode,  
 @period_start 		datetime,   --mod004
 @period_end 		datetime --mod004
)
AS
DECLARE  @rowcount smCounter,  @return_status smErrorCode,  @co_asset_id1 smSurrogateKey, 
 @co_asset_id2 smSurrogateKey,  @is_imported smLogical,  @co_asset_id smSurrogateKey, 
 @co_asset_book_id smSurrogateKey,  @asset_first_num smControlNumber,  @asset_secnd_num smControlNumber, 
 @cost smMoneyZero,  @accum_depr smMoneyZero,  @value smMoneyZero,  @asset_total_val smMoneyZero, 
 @depr_total_val smMoneyZero,  @addition_val smMoneyZero,  @revaluation_val smMoneyZero, 
 @improvement_val smMoneyZero,  @adjustment_val smMoneyZero,  @impairment_val smMoneyZero, 
 @disposition_val smMoneyZero,  @depreciation_val smMoneyZero,  @profile_date smApplyDate, 
 @fiscal_period_start smApplyDate,  @fiscal_period_end smApplyDate,  @total_string smStringText,
 /* mod001 */
 @open_wdv smMoneyZero,
 @close_wdv smMoneyZero,
 @cost_open_bal  smMoneyZero,
 @cost_close_bal smMoneyZero,
 @depr_open_bal  smMoneyZero,
 @depr_close_bal smMoneyZero,
 @cost_additions smMoneyZero,
 @cost_disposals smMoneyZero,
/* @cls_id smSurrogateKey, */
 @original_cost smMoneyZero	,
/* @activity_state smallint	, */
 @company_id	 smCompanyID,
 @company_name   varchar(30),
 @curr_precision int,
 @rounding_factor float,
  @result	smErrorCode

 

/* mod002 moved from just prior to insert into anz_amFar at end of stored proc */

/*DELETE FROM anz_amFar*/
 
/*IF ( @debug_level > 1 )
SELECT "tmp/ampdpdrp.sp" + ", line " + STR( 104, 5 ) + " -- ENTRY: " 
*/

/* mod001 */
/*
IF @activity_str = "All States"
	SELECT @activity_state = -1
ELSE IF @activity_str = "Active"
	SELECT @activity_state = 0
ELSE IF @activity_str = "To be Disposed"
	SELECT @activity_state = 1
ELSE IF @activity_str = "Added"
	SELECT @activity_state = 100
ELSE IF @activity_str = "Disposed"
	SELECT @activity_state = 101

SELECT @activity_state activity_state
*/
/* mod001 - get the company_id */
SELECT @company_id = company_id,
	   @company_name = company_name	
FROM   glco


EXEC	@result = amGetCurrencyPrecision_sp
					@curr_precision		OUTPUT,
					@rounding_factor 	OUTPUT

/*select @profile_date = DATEADD(dd,(@period_start -(SIGN(@period_start)*693596)),"19000101")		
select @fiscal_period_start = DATEADD(dd,(@period_start -(SIGN(@period_start)*693596)),"19000101")	
select @fiscal_period_end = DATEADD(dd,(@period_end -(SIGN(@period_end)*693596)),"19000101")	*/	

SELECT 	@fiscal_period_start 	= CONVERT(datetime, @period_start)
SELECT 	@fiscal_period_end 		= CONVERT(datetime, @period_end)
SELECT  @profile_date = CONVERT(datetime, @period_start)

/*IF @asset_ctrl_num1 in ("<Start>",'')  or @asset_ctrl_num1 is null --mod004
BEGIN 
SELECT @asset_ctrl_num1 = MIN(asset_ctrl_num) 
FROM amasset 
WHERE company_id = @company_id 
END*/

/*IF @asset_ctrl_num2 in ( "<End>",'') or @asset_ctrl_num2 is null   --mod004
BEGIN 
  SELECT @asset_ctrl_num2 = MAX(asset_ctrl_num) 

  FROM amasset 
  WHERE company_id = @company_id
END
IF @asset_ctrl_num2 >= @asset_ctrl_num1 
BEGIN 
SELECT @asset_first_num = @asset_ctrl_num1 
SELECT @asset_secnd_num = @asset_ctrl_num2 
END
ELSE
BEGIN 
  SELECT @asset_first_num = @asset_ctrl_num2 
  SELECT @asset_secnd_num = @asset_ctrl_num1 
END   */                
/* mod001 
  CREATE table #ampdrep 
(
 asset_ctrl_num char(17) NULL,  co_asset_id int NULL,  asset_description varchar(40) NULL, 
 account_type tinyint NULL,  start_value float NULL,  addition float NULL,  improvements float NULL, 
 revaluation float NULL,  adjustment float NULL,  impairment float NULL,  disposition float NULL, 
 depreciation float NULL,  end_value float NULL,
 acquisition_date datetime NULL, 
 asset_type_code varchar(8) NULL,
 proceeds float NULL,
 gain_loss float NULL
)
*/
/*CREATE table #amfar
(
 asset_ctrl_num 	char(17) NULL,  
 co_asset_id 		int NULL,  
 asset_description 	varchar(40) NULL, 
 open_wdv 			float NULL,  
 cost_open_bal  	float NULL,
 cost_additions 	float NULL,  
 cost_disposals 	float NULL, 
 cost_close_bal 	float NULL,
 depr_open_bal  	float NULL,
 ytd_depr_exp   	float NULL,
 prd_accum_depr		float NULL,
 depr_disposals 	float NULL,
 depr_close_bal 	float NULL,
 close_wdv      	float NULL,
 proceeds			float NULL,
 gain_loss			float NULL,
 acquisition_date 	datetime NULL,
 in_service_date 	datetime NULL,
 asset_type_code 	varchar(8) NULL,
 type_description 	varchar(40) NULL,
 location_code		varchar(8) NULL,
 location_description varchar(40) NULL,*/
/* classification_code varchar(8) NULL,
   classification_description varchar(40) NULL,
*/
 /*category_code 		varchar(8) NULL,
 depr_rule_code		varchar(8) NULL,
 annual_depr_rate	float NULL,
 depr_method_id		int NULL,
 depr_method_code	varchar(8) NULL
)*/

                         
 /* CREATE TABLE #amassets 
(co_asset_id int NOT NULL)*/
 

  /*IF @activity_state = 3 --mod004 from 9	
	BEGIN     
	  IF @select_assets = 0 
	  BEGIN      
  
	      INSERT INTO #amassets 
		 (  co_asset_id ) 
	      SELECT  co_asset_id
	      FROM amasset 
	      WHERE company_id = @company_id 
	      AND asset_ctrl_num
	      BETWEEN @asset_first_num AND @asset_secnd_num 
	      SELECT @rowcount = @@rowcount 

	  END 
	  ELSE 
	  BEGIN       
	    SELECT @is_imported = @select_assets - 1  
		INSERT INTO #amassets 
		 (  co_asset_id )
	    SELECT  co_asset_id
	    FROM amasset 
	    WHERE company_id = @company_id 
	    AND asset_ctrl_num
	    BETWEEN @asset_first_num AND @asset_secnd_num  
		AND is_imported = @is_imported 

    	SELECT @rowcount = @@rowcount 
	  END
	END
  ELSE
	BEGIN     
	  IF @select_assets = 0 
	  BEGIN 
	    INSERT INTO #amassets  (co_asset_id )
	    SELECT  co_asset_id
	    FROM amasset 
	    WHERE company_id = @company_id  
		AND asset_ctrl_num BETWEEN @asset_first_num AND @asset_secnd_num 
	    	AND activity_state = @activity_state 

		-- mod004 if an asset has been disposed but not disposed during the periods entered then print it
		INSERT INTO #amassets  (  co_asset_id ) 
		SELECT  co_asset_id
		FROM amasset 
		WHERE company_id = @company_id  
		AND asset_ctrl_num BETWEEN @asset_first_num AND @asset_secnd_num 
		AND disposition_date > @fiscal_period_end
	   
	    SELECT @rowcount = count(*) from #amassets

	  END 
	  ELSE 
	  BEGIN 
	      
	    SELECT @is_imported = @select_assets - 1  
		INSERT INTO #amassets  (  co_asset_id ) 
	    SELECT  co_asset_id
	    FROM amasset 
	    WHERE company_id = @company_id  
		AND asset_ctrl_num BETWEEN @asset_first_num AND @asset_secnd_num 
	    AND is_imported = @is_imported  
		AND activity_state = @activity_state 

		-- mod004 if an asset has been disposed but not disposed during the periods entered then print it
		INSERT INTO #amassets  (  co_asset_id ) 
		SELECT  co_asset_id
		FROM amasset 
		WHERE company_id = @company_id  
		AND asset_ctrl_num BETWEEN @asset_first_num AND @asset_secnd_num 
		   AND is_imported = @is_imported  
		AND disposition_date > @fiscal_period_end
    
		 SELECT @rowcount = count(*) from #amassets

	  END
	END*/

	
/*IF @rowcount=0
BEGIN 
  SELECT *
  FROM #amfar 
  RETURN
END  */

/* mod001
INSERT #ampdrep 
(
 co_asset_id,  account_type,  start_value,  addition,  improvements,  revaluation, 
 adjustment,  impairment,  disposition,  depreciation,  end_value, 
 acquisition_date, asset_type_code, proceeds, gain_loss
)
SELECT  co_asset_id,  0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,
 	null, "", proceeds, gain_loss
FROM amastbk 
WHERE book_code = @book_code 
AND co_asset_id IN (SELECT co_asset_id
					FROM #amassets ) 

 INSERT #ampdrep 
( co_asset_id,  account_type,  start_value,  addition,  improvements,  revaluation, 
 adjustment,  impairment,  disposition,  depreciation,  end_value,
 acquisition_date, asset_type_code, proceeds, gain_loss )
SELECT  co_asset_id,  1,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,
 	null, "", proceeds, gain_loss
FROM amastbk 
WHERE book_code = @book_code 
AND co_asset_id IN (SELECT co_asset_id
					FROM #amassets ) 


 INSERT #ampdrep 
( co_asset_id,  account_type,  start_value,  addition,  improvements,  revaluation, 
 adjustment,  impairment,  disposition,  depreciation,  end_value,
 acquisition_date, asset_type_code, proceeds, gain_loss )
SELECT  co_asset_id,  2,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,
    null, "", proceeds, gain_loss
FROM amastbk 
WHERE book_code = @book_code 
AND co_asset_id IN (SELECT co_asset_id
					FROM #amassets ) 
*/

INSERT #amfar (co_asset_id, open_wdv, cost_open_bal,
				cost_additions, cost_disposals, cost_close_bal, depr_open_bal, 
				ytd_depr_exp, depr_disposals, depr_close_bal, close_wdv, 
				proceeds, gain_loss)
SELECT  co_asset_id,  0.0,  0.0,  
		0.0,  0.0,  0.0,  0.0,  
		0.0,  0.0,  0.0,  0.0, 
		proceeds, 0
FROM amastbk 
WHERE book_code = @book_code 
AND co_asset_id IN (SELECT co_asset_id
					FROM #amassets ) 


SELECT co_asset_id,  co_asset_book_id 
INTO #counter1
FROM amastbk
WHERE book_code = @book_code 
AND co_asset_id IN (SELECT co_asset_id
					FROM #amassets ) 

					
WHILE 1=1
BEGIN  
  SET ROWCOUNT 1 
 
  SELECT @co_asset_id = co_asset_id,  
  		@co_asset_book_id = co_asset_book_id 
  FROM #counter1 

  IF @@rowcount = 0 
  BEGIN 
    SET ROWCOUNT 0 
    BREAK 
  END    
  
  /* mod002 */
  SELECT @original_cost = original_cost
  FROM amasset
  WHERE co_asset_id = @co_asset_id
  
  EXEC @return_status = amGetPrfRep_sp @co_asset_book_id,  @profile_date,  	@curr_precision,
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

    ---- mod004 SELECT @asset_total_val = isnull(@asset_total_val,0.0) + isnull(@cost,0.0)   
     -- mod004 
    SELECT @asset_total_val = current_cost from amastprf
	where co_asset_book_id =  @co_asset_book_id and fiscal_period_end = (select max(fiscal_period_end) from amastprf
	where co_asset_book_id = @co_asset_book_id and fiscal_period_end <= @fiscal_period_end)


	EXEC @return_status = amGetValueRep_sp 
			 @co_asset_book_id,  0,  @fiscal_period_start,  @fiscal_period_end,  10,@curr_precision,
 @value OUTPUT 
    IF ( @return_status != 0 )  
		RETURN @return_status 
    SELECT @addition_val = isnull(@value,0.0) 
    -- mod004 SELECT @asset_total_val = @asset_total_val + isnull(@value,0.0)   
-- mod004 
    SELECT @asset_total_val = current_cost from amastprf
	where co_asset_book_id =  @co_asset_book_id and fiscal_period_end = (select max(fiscal_period_end) from amastprf
	where co_asset_book_id = @co_asset_book_id and fiscal_period_end <= @fiscal_period_end)


	EXEC @return_status = amGetValueRep_sp  @co_asset_book_id,  0,  @fiscal_period_start,  @fiscal_period_end,  40, 
		@curr_precision, @value output 
    IF ( @return_status != 0 )  RETURN @return_status 
    SELECT @revaluation_val = isnull(@value,0.0) 
 --mod004    SELECT @asset_total_val = @asset_total_val + isnull(@value,0.0)   
-- mod004 
    SELECT @asset_total_val = current_cost from amastprf
	where co_asset_book_id =  @co_asset_book_id and fiscal_period_end = (select max(fiscal_period_end) from amastprf
	where co_asset_book_id = @co_asset_book_id and fiscal_period_end <= @fiscal_period_end)


	EXEC @return_status = amGetValueRep_sp 
			 @co_asset_book_id,  0,  @fiscal_period_start,  @fiscal_period_end,  20, @curr_precision, @value output 
    IF ( @return_status != 0 )  RETURN @return_status 
    SELECT @improvement_val = isnull(@value,0.0) 
    -- mod004 SELECT @asset_total_val = @asset_total_val + isnull(@value,0.0) 
-- mod004  
    SELECT @asset_total_val = current_cost from amastprf
	where co_asset_book_id =  @co_asset_book_id and fiscal_period_end = (select max(fiscal_period_end) from amastprf
	where co_asset_book_id = @co_asset_book_id and fiscal_period_end <= @fiscal_period_end)

	EXEC @return_status = amGetValueRep_sp 
		 @co_asset_book_id,  0,  @fiscal_period_start,  @fiscal_period_end,  42, @curr_precision, @value output 
    IF ( @return_status != 0 )  RETURN @return_status 
    SELECT @adjustment_val = isnull(@value,0.0) 
    -- mod004 SELECT @asset_total_val = @asset_total_val + isnull(@value,0.0)   
-- mod004
    SELECT @asset_total_val = current_cost from amastprf
	where co_asset_book_id =  @co_asset_book_id and fiscal_period_end = (select max(fiscal_period_end) from amastprf
	where co_asset_book_id = @co_asset_book_id and fiscal_period_end <= @fiscal_period_end)

	EXEC @return_status = amGetValueRep_sp 
		 @co_asset_book_id,  0,  @fiscal_period_start,  @fiscal_period_end,  41, @curr_precision, @value output 
    IF ( @return_status != 0 )  RETURN @return_status 
    SELECT @impairment_val = isnull(@value,0.0) 
    -- mod004 SELECT @asset_total_val = @asset_total_val + isnull(@value,0.0)   
-- mod004
    SELECT @asset_total_val = current_cost from amastprf
	where co_asset_book_id =  @co_asset_book_id and fiscal_period_end = (select max(fiscal_period_end) from amastprf
	where co_asset_book_id = @co_asset_book_id and fiscal_period_end <= @fiscal_period_end)

	EXEC @return_status = amGetValueRep_sp 
		 @co_asset_book_id,  0,  @fiscal_period_start,  @fiscal_period_end,  30, @curr_precision, @value output 
    IF ( @return_status != 0 )  RETURN @return_status 
    SELECT @disposition_val = isnull(@value,0.0) 
    -- mod004 SELECT @asset_total_val = @asset_total_val + isnull(@value,0.0)  
-- mod004 
    SELECT @asset_total_val = current_cost from amastprf
	where co_asset_book_id =  @co_asset_book_id and fiscal_period_end = (select max(fiscal_period_end) from amastprf
	where co_asset_book_id = @co_asset_book_id and fiscal_period_end <= @fiscal_period_end)

	EXEC @return_status = amGetValueRep_sp 
		 @co_asset_book_id,  0,  @fiscal_period_start,  @fiscal_period_end,  50, @curr_precision, @value output 
    IF ( @return_status != 0 )  RETURN @return_status 
    SELECT @depreciation_val = isnull(@value,0.0) 
    -- mod004 SELECT @asset_total_val = @asset_total_val + isnull(@value,0.0)   
-- mod004
    SELECT @asset_total_val = current_cost from amastprf
	where co_asset_book_id =  @co_asset_book_id and fiscal_period_end = (select max(fiscal_period_end) from amastprf
	where co_asset_book_id = @co_asset_book_id and fiscal_period_end <= @fiscal_period_end)

	EXEC @return_status = amGetValueRep_sp 
		 @co_asset_book_id,  0,  @fiscal_period_start,  @fiscal_period_end,  60, @curr_precision, @value output 
    IF ( @return_status != 0 )  RETURN @return_status 
    SELECT @depreciation_val = @value + isnull(@value, 0.0) 
    -- mod004 SELECT @asset_total_val = @asset_total_val + isnull(@value, 0.0)   
-- mod004
    SELECT @asset_total_val = current_cost from amastprf
	where co_asset_book_id =  @co_asset_book_id and fiscal_period_end = (select max(fiscal_period_end) from amastprf
	where co_asset_book_id = @co_asset_book_id and fiscal_period_end <= @fiscal_period_end)

	EXEC @return_status = amGetValueRep_sp 
		 @co_asset_book_id,  0,  @fiscal_period_start,  @fiscal_period_end,  70,@curr_precision,  @value output 
    IF ( @return_status != 0 )  RETURN @return_status 

    SELECT @disposition_val = @disposition_val + isnull(@value,0.0) 
    -- mod004 SELECT @asset_total_val = @asset_total_val + isnull(@value,0.0) 
-- mod004 
    SELECT @asset_total_val = current_cost from amastprf
	where co_asset_book_id =  @co_asset_book_id and fiscal_period_end = (select max(fiscal_period_end) from amastprf
	where co_asset_book_id = @co_asset_book_id and fiscal_period_end <= @fiscal_period_end)

	/* mod001
    UPDATE #ampdrep 
    SET start_value = ISNULL(@cost,0.0),  
		addition = ISNULL(@addition_val,0.0),  
		revaluation = ISNULL(@revaluation_val,0.0), 
 		improvements = ISNULL(@improvement_val,0.0),  
		adjustment = ISNULL(@adjustment_val,0.0), 
		impairment = ISNULL(@impairment_val,0.0),  
		disposition = ISNULL(@disposition_val,0.0), 
 		depreciation = ISNULL(@depreciation_val,0.0),  
		end_value = ISNULL(@asset_total_val,0.0)
    WHERE co_asset_id = @co_asset_id  AND account_type = 0 
    SELECT @return_status = @@error 
	*/
	
    IF ( @return_status != 0 )  RETURN @return_status 

	/* don't need this now	
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
	*/		
				
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
/*----------------------------------- account_type 1 ----------------------------- */  
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
		 @fiscal_period_end,  42, @curr_precision, @value output 
    IF ( @return_status != 0 )  RETURN @return_status 
    IF isnull(@value,0.0) = 0.0 
	    SELECT @adjustment_val = isnull(@value,0.0) 
    ELSE 
	    SELECT @adjustment_val = -(isnull(@value,0.0)) 
    SELECT @depr_total_val = @depr_total_val - isnull(@value,0.0)   
	
	EXEC @return_status = amGetValueRep_sp 
		 @co_asset_book_id,  1,  @fiscal_period_start,  @fiscal_period_end,  41,@curr_precision,  @value output 
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
 
	/* @accum_depr returned from amGetPrfRep_sp above */
    IF isnull(@accum_depr, 0.0) = 0.0 
	    SELECT @accum_depr = isnull(@accum_depr, 0.0) 
    ELSE 
	    SELECT @accum_depr = -(isnull(@accum_depr, 0.0))  

	/* mod001
    UPDATE #ampdrep 
    SET  start_value = ISNULL(@accum_depr,0.0), 
		 addition = ISNULL(@addition_val,0.0),  
		 revaluation = ISNULL(@revaluation_val,0.0), 
		 improvements = ISNULL(@improvement_val,0.0),  
		 adjustment = ISNULL(@adjustment_val,0.0), 
		 impairment = ISNULL(@impairment_val,0.0),  
		 disposition = ISNULL(@disposition_val,0.0), 
		 depreciation = ISNULL(@depreciation_val,0.0),  
		 end_value = ISNULL(@depr_total_val,0.0) 
    WHERE co_asset_id = @co_asset_id  AND account_type = 1 
    SELECT @return_status = @@error 

    IF ( @return_status != 0 )  RETURN @return_status 
	*/


    SELECT  @depr_open_bal = ISNULL(@accum_depr,0.0),
    		@depr_close_bal = ISNULL(@accum_depr,0.0) + ISNULL(@depr_total_val,0.0) 
	
	
	UPDATE #amfar
	SET depr_open_bal = round(@depr_open_bal,2),
		ytd_depr_exp = round(@depreciation_val,2),
		prd_accum_depr = round(@depr_total_val, 2),
		depr_disposals = round(@disposition_val,2),
		depr_close_bal = round(@depr_close_bal,2),
		gain_loss = (@original_cost - (@depr_open_bal + @depreciation_val) - proceeds)*-1
	WHERE co_asset_id = @co_asset_id


	SELECT @return_status = @@error
	
	IF ( @return_status != 0 ) RETURN @return_status



  END   
  
  /* account_type 2 */  
  /* mod001 
  UPDATE #ampdrep 
  SET start_value = ISNULL(@cost, 0.0) - ISNULL(@accum_depr, 0.0), 
 	  end_value = ISNULL(@asset_total_val, 0.0) - ISNULL(@depr_total_val, 0.0) 
  WHERE co_asset_id = @co_asset_id 
  AND account_type = 2 
  */
  
  /* mod001 */
  SELECT @open_wdv = ISNULL(@cost, 0.0) - ISNULL(@depr_open_bal, 0.0),
    	 @close_wdv = ISNULL(@asset_total_val, 0.0) - ISNULL(@depr_close_bal, 0.0) 
  
  UPDATE #amfar
  SET open_wdv = round(@open_wdv,2),
	  close_wdv = round(@close_wdv,2)
  WHERE co_asset_id = @co_asset_id
  SELECT @return_status = @@error
	
  IF ( @return_status != 0 ) RETURN @return_status
  
  DELETE #counter1 
  SET ROWCOUNT 0
END    


/* mod001 */
UPDATE #amfar
SET #amfar.asset_ctrl_num = ISNULL(b.asset_ctrl_num,""), 
    #amfar.asset_description = ISNULL(b.asset_description,""),
	#amfar.acquisition_date = ISNULL(b.acquisition_date,""),		
	#amfar.in_service_date = ISNULL(b.placed_in_service_date,""),
	#amfar.asset_type_code = ISNULL(b.asset_type_code,""),
	#amfar.location_code = ISNULL(b.location_code,""),
	#amfar.category_code = ISNULL(b.category_code,"")
FROM #amfar,  amasset b 
WHERE #amfar.co_asset_id = b.co_asset_id           

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

/* If we want classification info later, this part can be put back in.
SELECT @cls_id = classification_id
FROM amclsdef
WHERE classification_name = "Cost Type"

UPDATE #amfar
SET a.classification_code = b.classification_code
FROM #amfar a, amastcls b
WHERE classification_id = @cls_id
AND b.co_asset_id = a.co_asset_id

UPDATE #amfar
SET a.classification_description = b.classification_description
FROM #amfar a, amcls b
WHERE b.classification_id = @cls_id
AND	a.classification_code = b.classification_code
*/

UPDATE #amfar
SET    #amfar.depr_rule_code = b.depr_rule_code
FROM   #amfar, amcatbk b
WHERE  #amfar.category_code = b.category_code
AND    b.book_code = @book_code 

UPDATE #amfar
SET    #amfar.annual_depr_rate = d.annual_depr_rate,
	   #amfar.depr_method_id = d.depr_method_id
FROM   #amfar, amdprrul d
WHERE  d.depr_rule_code = #amfar.depr_rule_code


UPDATE #amfar
SET    depr_method_code = "None"
WHERE  depr_method_id = 0

UPDATE #amfar
SET    depr_method_code = "SL%"
WHERE  depr_method_id = 1

UPDATE #amfar
SET    depr_method_code = "SLSL"
WHERE  depr_method_id = 2

UPDATE #amfar
SET    depr_method_code = "SLML"
WHERE  depr_method_id = 3

UPDATE #amfar
SET    depr_method_code = "DBal"
WHERE  depr_method_id = 4

UPDATE #amfar
SET    depr_method_code = "DBSL"
WHERE  depr_method_id = 5

UPDATE #amfar
SET    depr_method_code = "Man"
WHERE  depr_method_id = 7


EXEC @return_status = amGetString_sp  21,  @total_string OUTPUT

IF @return_status <> 0  RETURN @return_status  

/*
SELECT 	 asset_ctrl_num, asset_description, in_service_date, location_description,
			annual_depr_rate, depr_method_code, cost_close_bal, depr_open_bal,
			prd_accum_depr, depr_close_bal, close_wdv, asset_type_code,
			type_description,
			@asset_ctrl_num1 as asset_ctrl_num1, 
			@asset_ctrl_num2 as asset_ctrl_num2, 
			@book_code as book_code, 
			convert(varchar(12), @profile_date, 3) as period_start,
			convert(varchar(12), @fiscal_period_end, 3) as period_end,
			@company_name as company_name
FROM   	 #amfar
ORDER BY asset_type_code, asset_ctrl_num, co_asset_id
*/


INSERT INTO #anz_amFar (
 asset_ctrl_num	,  asset_description, in_service_date  , location_description,
 annual_depr_rate , depr_method_code , cost_close_bal	  , depr_open_bal	  ,
 prd_accum_depr	  , depr_close_bal	  , close_wdv		  , asset_type_code  ,
 type_description , asset_ctrl_num1  , asset_ctrl_num2  ,
 book_code		  , period_start	  , period_end		  , company_name, org_id, region_id	  
)
SELECT distinct	 asset_ctrl_num, asset_description, in_service_date, location_description,
			annual_depr_rate, depr_method_code, cost_close_bal, depr_open_bal,
			prd_accum_depr, depr_close_bal, close_wdv, asset_type_code,
			type_description,
			'asset1' as asset_ctrl_num1, 
			'asset2' as asset_ctrl_num2, 
			@book_code as book_code, 
			convert(varchar(12), @fiscal_period_start, 3) as period_start,
			convert(varchar(12), @fiscal_period_end, 3) as period_end,
			@company_name as company_name,
			org_id, region_id
FROM   	 #amfar



/*DROP TABLE #amfar
DROP TABLE #amassets*/
/*IF ( @debug_level > 1 )
SELECT "tmp/tmp_amFixedAssetRep.sp" + ", line " + STR( 957, 5 ) + " -- EXIT: " 
*/
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amFar_sp] TO [public]
GO
