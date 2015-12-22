SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ammovementreport_sp] 
(

   @book_code smBookCode,  
   @period_start int,	
   @period_end int,	
   @debug_level smDebugLevel = 0 
)
AS DECLARE  @rowcount smCounter,  @return_status smErrorCode,  @co_asset_id1 smSurrogateKey, 
 @co_asset_id2 smSurrogateKey,  @is_imported smLogical,  @co_asset_id smSurrogateKey, 
 @co_asset_book_id smSurrogateKey,  @asset_first_num smControlNumber,  @asset_secnd_num smControlNumber, 
 @cost smMoneyZero,  @accum_depr smMoneyZero,  @value smMoneyZero,  @asset_total_val smMoneyZero, 
 @depr_total_val smMoneyZero,  @addition_val smMoneyZero,  @revaluation_val smMoneyZero, 
 @improvement_val smMoneyZero,  @adjustment_val smMoneyZero,  @impairment_val smMoneyZero, 
 @disposition_val smMoneyZero,  @depreciation_val smMoneyZero,  @profile_date smApplyDate, 
 @fiscal_period_start smApplyDate,  @fiscal_period_end smApplyDate,  @total_string smStringText,
 @company_id 	smCompanyID,
 @company_name	varchar(30),
 @curr_precision int,
 @rounding_factor float,
 @result	smErrorCode

IF ( @debug_level > 1 ) SELECT 'tmp/ampdpdrp.sp' + ', line ' + STR( 104, 5 ) + ' -- ENTRY: ' 


EXEC	@result = amGetCurrencyPrecision_sp
					@curr_precision		OUTPUT,
					@rounding_factor 	OUTPUT
SELECT  @company_id = company_id,
		@company_name = company_name
FROM    glco

select @profile_date = DATEADD(dd,(@period_start -(SIGN(@period_start)*693596)),'19000101')		
select @fiscal_period_start = DATEADD(dd,(@period_start -(SIGN(@period_start)*693596)),'19000101')	
select @fiscal_period_end = DATEADD(dd,(@period_end -(SIGN(@period_end)*693596)),'19000101')		

                 

CREATE table #ampdrep 
(
 asset_ctrl_num char(17) NULL,  
 co_asset_id int NULL,  asset_description varchar(40) NULL, 
 account_type tinyint NULL,  start_value float NULL,  addition float NULL,  improvements float NULL, 
 revaluation float NULL,  adjustment float NULL,  impairment float NULL,  disposition float NULL, 
 depreciation float NULL,  end_value float NULL ,
 asset_type_code 	varchar(12) NULL,		
 type_description	varchar(40) NULL,		
 type_code_id		smallint NULL,			
 org_id 		varchar(30) NULL,
 region_id		varchar(30)NULL 	
)


-- account type = 0: asset 
INSERT 	#ampdrep 
	(type_code_id,
 	co_asset_id,  account_type,  start_value,  addition,  improvements,  revaluation, 
 	adjustment,  impairment,  disposition,  depreciation,  end_value )
SELECT  0, co_asset_id,  0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0 FROM amastbk 
WHERE book_code = @book_code AND co_asset_id IN ( SELECT co_asset_id FROM #amassets ) 

-- account type = 1: accumulated depreciation
INSERT #ampdrep (type_code_id,
 	co_asset_id,  account_type,  start_value,  addition,  improvements,  revaluation, 
 	adjustment,  impairment,  disposition,  depreciation,  end_value )
SELECT  0, co_asset_id,  1,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0 FROM amastbk 
WHERE 	book_code = @book_code AND co_asset_id IN ( SELECT co_asset_id FROM #amassets ) 

-- account type = 2: Revaluation
INSERT 	#ampdrep (type_code_id,
 	co_asset_id,  account_type,  start_value,  addition,  improvements,  revaluation, 
 	adjustment,  impairment,  disposition,  depreciation,  end_value )
SELECT  0, co_asset_id,  2,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0 FROM amastbk 
WHERE 	book_code = @book_code AND co_asset_id IN ( SELECT co_asset_id FROM #amassets ) 

-- account type = 3: Fixed assets clearing
INSERT 	#ampdrep (type_code_id,
 	co_asset_id,  account_type,  start_value,  addition,  improvements,  revaluation, 
 	adjustment,  impairment,  disposition,  depreciation,  end_value )
SELECT  0, co_asset_id,  3,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0 FROM amastbk 
WHERE 	book_code = @book_code AND co_asset_id IN ( SELECT co_asset_id FROM #amassets ) 

-- account type = 4: Proceeds
INSERT 	#ampdrep (type_code_id,
 	co_asset_id,  account_type,  start_value,  addition,  improvements,  revaluation, 
 	adjustment,  impairment,  disposition,  depreciation,  end_value )
SELECT  0, co_asset_id,  4,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0 FROM amastbk 
WHERE 	book_code = @book_code AND co_asset_id IN ( SELECT co_asset_id FROM #amassets ) 

-- account type = 5: Depreciation Expenses
INSERT 	#ampdrep (type_code_id,
 	co_asset_id,  account_type,  start_value,  addition,  improvements,  revaluation, 
 	adjustment,  impairment,  disposition,  depreciation,  end_value )
SELECT  0, co_asset_id,  5,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0 FROM amastbk 
WHERE 	book_code = @book_code AND co_asset_id IN ( SELECT co_asset_id FROM #amassets ) 

-- account type = 6: Cost of removals
INSERT 	#ampdrep (type_code_id,
 	co_asset_id,  account_type,  start_value,  addition,  improvements,  revaluation, 
 	adjustment,  impairment,  disposition,  depreciation,  end_value )
SELECT  0, co_asset_id,  6,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0 FROM amastbk 
WHERE 	book_code = @book_code AND co_asset_id IN ( SELECT co_asset_id FROM #amassets ) 

-- account type = 7: Adjustments
INSERT 	#ampdrep (type_code_id,
 	co_asset_id,  account_type,  start_value,  addition,  improvements,  revaluation, 
 	adjustment,  impairment,  disposition,  depreciation,  end_value )
SELECT  0, co_asset_id,  7,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0 FROM amastbk 
WHERE 	book_code = @book_code AND co_asset_id IN ( SELECT co_asset_id FROM #amassets ) 

-- account type = 8: Gain or Loss
INSERT 	#ampdrep (type_code_id,
 	co_asset_id,  account_type,  start_value,  addition,  improvements,  revaluation, 
 	adjustment,  impairment,  disposition,  depreciation,  end_value )
SELECT  0, co_asset_id,  8,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0 FROM amastbk 
WHERE 	book_code = @book_code AND co_asset_id IN ( SELECT co_asset_id FROM #amassets ) 

-- account type = 9: Immediate Expense
INSERT 	#ampdrep (type_code_id,
 	co_asset_id,  account_type,  start_value,  addition,  improvements,  revaluation, 
 	adjustment,  impairment,  disposition,  depreciation,  end_value )
SELECT  0, co_asset_id,  9,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0 FROM amastbk 
WHERE 	book_code = @book_code AND co_asset_id IN ( SELECT co_asset_id FROM #amassets ) 

-- account type = 10: Impairment
INSERT 	#ampdrep (type_code_id,
 	co_asset_id,  account_type,  start_value,  addition,  improvements,  revaluation, 
 	adjustment,  impairment,  disposition,  depreciation,  end_value )
SELECT  0, co_asset_id,  10,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0 FROM amastbk 
WHERE 	book_code = @book_code AND co_asset_id IN ( SELECT co_asset_id FROM #amassets ) 


SELECT 	co_asset_id,  co_asset_book_id INTO #counter1 
FROM 	amastbk 
WHERE 	book_code = @book_code 
	AND co_asset_id IN ( SELECT co_asset_id FROM #amassets )  

WHILE 1=1 BEGIN   
SET ROWCOUNT 1 
  SELECT @co_asset_id = co_asset_id,  @co_asset_book_id = co_asset_book_id  
  FROM #counter1 
 IF @@rowcount = 0  
	BEGIN  
		SET ROWCOUNT 0  
		BREAK  
	END    


EXEC 	@return_status = amGetPrfRep_sp @co_asset_book_id,  @profile_date, @curr_precision, 
	@cost OUTPUT, @accum_depr OUTPUT  

  	BEGIN    
		SELECT  @asset_total_val = 0.0,  @addition_val = 0.0,  @revaluation_val = 0.0,  @improvement_val = 0.0, 
		@adjustment_val = 0.0,  @impairment_val = 0.0,  @disposition_val = 0.0,  @depreciation_val = 0.0 

     SELECT @asset_total_val = current_cost from amastprf
	where co_asset_book_id =  @co_asset_book_id and fiscal_period_end = (select max(fiscal_period_end) from amastprf
	where co_asset_book_id = @co_asset_book_id and fiscal_period_end <= @fiscal_period_end)

-- ADDITION
EXEC @return_status = amGetValueRep_sp 
 @co_asset_book_id,  0,  @fiscal_period_start,  @fiscal_period_end,  10, @curr_precision, @value OUTPUT 
 IF ( @return_status != 0 )  RETURN @return_status  SELECT @addition_val = isnull(@value,0.0) 
 
     SELECT @asset_total_val = current_cost from amastprf
	where co_asset_book_id =  @co_asset_book_id and fiscal_period_end = (select max(fiscal_period_end) from amastprf
	where co_asset_book_id = @co_asset_book_id and fiscal_period_end <= @fiscal_period_end)

-- REVALUATION
EXEC @return_status = amGetValueRep_sp 
 @co_asset_book_id,  0,  @fiscal_period_start,  @fiscal_period_end,  40,  @curr_precision, @value output 
 IF ( @return_status != 0 )  RETURN @return_status  
SELECT @revaluation_val = isnull(@value,0.0) 

     SELECT @asset_total_val = current_cost from amastprf
	where co_asset_book_id =  @co_asset_book_id and fiscal_period_end = (select max(fiscal_period_end) from amastprf
	where co_asset_book_id = @co_asset_book_id and fiscal_period_end <= @fiscal_period_end)

-- IMPROVEMENT
EXEC @return_status = amGetValueRep_sp 
 @co_asset_book_id,  0,  @fiscal_period_start,  @fiscal_period_end,  20,   @curr_precision, @value output 
 IF ( @return_status != 0 )  RETURN @return_status  SELECT @improvement_val = isnull(@value,0.0) 
 
     SELECT @asset_total_val = current_cost from amastprf
	where co_asset_book_id =  @co_asset_book_id and fiscal_period_end = (select max(fiscal_period_end) from amastprf
	where co_asset_book_id = @co_asset_book_id and fiscal_period_end <= @fiscal_period_end)

-- ADJUSTMENT
EXEC @return_status = amGetValueRep_sp 
 @co_asset_book_id,  0,  @fiscal_period_start,  @fiscal_period_end,  42,  @curr_precision, @value output 
 IF ( @return_status != 0 )  
    RETURN @return_status  
SELECT @adjustment_val = isnull(@value,0.0) 
 
     SELECT @asset_total_val = current_cost from amastprf
	where co_asset_book_id =  @co_asset_book_id and fiscal_period_end = (select max(fiscal_period_end) from amastprf
	where co_asset_book_id = @co_asset_book_id and fiscal_period_end <= @fiscal_period_end)

-- IMPAIREMENT
EXEC @return_status = amGetValueRep_sp 
 @co_asset_book_id,  0,  @fiscal_period_start,  @fiscal_period_end,  41,  @curr_precision, @value output 
 IF ( @return_status != 0 )  RETURN @return_status  
SELECT @impairment_val = isnull(@value,0.0) 

     SELECT @asset_total_val = current_cost from amastprf
	where co_asset_book_id =  @co_asset_book_id and fiscal_period_end = (select max(fiscal_period_end) from amastprf
	where co_asset_book_id = @co_asset_book_id and fiscal_period_end <= @fiscal_period_end)

-- DISPOSAL
EXEC @return_status = amGetValueRep_sp 
 @co_asset_book_id,  0,  @fiscal_period_start,  @fiscal_period_end,  30,  @curr_precision, @value output 
 IF ( @return_status != 0 )  RETURN @return_status  SELECT @disposition_val = isnull(@value,0.0) 
 
     SELECT @asset_total_val = current_cost from amastprf
	where co_asset_book_id =  @co_asset_book_id and fiscal_period_end = (select max(fiscal_period_end) from amastprf
	where co_asset_book_id = @co_asset_book_id and fiscal_period_end <= @fiscal_period_end)

-- DEPRECIATION
EXEC @return_status = amGetValueRep_sp 
 @co_asset_book_id,  0,  @fiscal_period_start,  @fiscal_period_end,  50,  @curr_precision, @value output 
 IF ( @return_status != 0 )  RETURN @return_status  SELECT @depreciation_val = isnull(@value,0.0) 
 
     SELECT @asset_total_val = current_cost from amastprf
	where co_asset_book_id =  @co_asset_book_id and fiscal_period_end = (select max(fiscal_period_end) from amastprf
	where co_asset_book_id = @co_asset_book_id and fiscal_period_end <= @fiscal_period_end)

-- DEPRECIATION ADJUSTMENT
 EXEC @return_status = amGetValueRep_sp 
 @co_asset_book_id,  0,  @fiscal_period_start,  @fiscal_period_end,  60,  @curr_precision, @value output 
 IF ( @return_status != 0 )  RETURN @return_status  SELECT @depreciation_val = @value + isnull(@value, 0.0) 
 

     SELECT @asset_total_val = current_cost from amastprf
	where co_asset_book_id =  @co_asset_book_id and fiscal_period_end = (select max(fiscal_period_end) from amastprf
	where co_asset_book_id = @co_asset_book_id and fiscal_period_end <= @fiscal_period_end)

-- PARTIAL DISPOSITION
EXEC @return_status = amGetValueRep_sp 
 @co_asset_book_id,  0,  @fiscal_period_start,  @fiscal_period_end,  70,  @curr_precision, @value output 
 IF ( @return_status != 0 )  RETURN @return_status  SELECT @disposition_val = @disposition_val + isnull(@value,0.0) 
 

     SELECT @asset_total_val = current_cost from amastprf
	where co_asset_book_id =  @co_asset_book_id and fiscal_period_end = (select max(fiscal_period_end) from amastprf
	where co_asset_book_id = @co_asset_book_id and fiscal_period_end <= @fiscal_period_end)

UPDATE #ampdrep 
 SET start_value = ISNULL(@cost,0.0),  addition = ISNULL(@addition_val,0.0),  revaluation = ISNULL(@revaluation_val,0.0), 
 improvements = ISNULL(@improvement_val,0.0),  adjustment = ISNULL(@adjustment_val,0.0), 
 impairment = ISNULL(@impairment_val,0.0),  disposition = ISNULL(@disposition_val,0.0), 
 depreciation = ISNULL(@depreciation_val,0.0),  end_value = ISNULL(@asset_total_val,0.0) 
 WHERE co_asset_id = @co_asset_id  AND account_type = 0  

 SELECT @return_status = @@error 
 IF ( @return_status != 0 )  RETURN 
 @return_status  END   BEGIN    SELECT  @depr_total_val = 0.0, 
 @addition_val = 0.0,  @revaluation_val = 0.0,  @improvement_val = 0.0,  @adjustment_val = 0.0, 
 @impairment_val = 0.0,  @disposition_val = 0.0,  @depreciation_val = 0.0  SELECT @depr_total_val = @depr_total_val - isnull(@accum_depr,0.0) 
  
 EXEC @return_status = amGetValueRep_sp  @co_asset_book_id,  1,  @fiscal_period_start, 
 @fiscal_period_end,  10,  @curr_precision, @value output  IF ( @return_status != 0 )  RETURN @return_status 
 IF isnull(@value,0.0) = 0.0  SELECT @addition_val = isnull(@value,0.0)  ELSE  SELECT @addition_val = -(isnull(@value,0.0)) 
 SELECT @depr_total_val = @depr_total_val - isnull(@value,0.0)   EXEC @return_status = amGetValueRep_sp 
 @co_asset_book_id,  1,  @fiscal_period_start,  @fiscal_period_end,  40,  @curr_precision, @value output 
 IF ( @return_status != 0 )  RETURN @return_status  IF isnull(@value,0.0) = 0.0  SELECT @revaluation_val = isnull(@value,0.0) 
 ELSE  SELECT @revaluation_val = -(isnull(@value,0.0))  SELECT @depr_total_val = @depr_total_val - isnull(@value,0.0) 
  EXEC @return_status = amGetValueRep_sp  @co_asset_book_id,  1,  @fiscal_period_start, 
 @fiscal_period_end,  20, @curr_precision,  @value output  IF ( @return_status != 0 )  RETURN @return_status 
 IF isnull(@value,0.0) = 0.0  SELECT @improvement_val = isnull(@value,0.0)  ELSE 
 SELECT @improvement_val = -(isnull(@value,0.0))  SELECT @depr_total_val = @depr_total_val - isnull(@value,0.0) 
  EXEC @return_status = amGetValueRep_sp  @co_asset_book_id,  1,  @fiscal_period_start, 
 @fiscal_period_end,  42,  @curr_precision, @value output  IF ( @return_status != 0 )  RETURN @return_status 
 IF isnull(@value,0.0) = 0.0  SELECT @adjustment_val = isnull(@value,0.0)  ELSE  SELECT @adjustment_val = -(isnull(@value,0.0)) 
 SELECT @depr_total_val = @depr_total_val - isnull(@value,0.0)   EXEC @return_status = amGetValueRep_sp 
 @co_asset_book_id,  1,  @fiscal_period_start,  @fiscal_period_end,  41,  @curr_precision, @value output 
 IF ( @return_status != 0 )  RETURN @return_status  IF isnull(@value,0.0) = 0.0  SELECT @impairment_val = isnull(@value,0.0) 
 ELSE  SELECT @impairment_val = -(isnull(@value,0.0))  SELECT @depr_total_val = @depr_total_val - isnull(@value,0.0) 
  EXEC @return_status = amGetValueRep_sp  @co_asset_book_id,  1,  @fiscal_period_start, 
 @fiscal_period_end,  30,  @curr_precision, @value OUTPUT  IF ( @return_status != 0 )  RETURN @return_status 
 IF isnull(@value,0.0) = 0.0  SELECT @disposition_val = isnull(@value,0.0)  ELSE 
 SELECT @disposition_val = -(isnull(@value,0.0))  SELECT @depr_total_val = @depr_total_val - isnull(@value,0.0) 
  EXEC @return_status = amGetValueRep_sp  @co_asset_book_id,  1,  @fiscal_period_start, 
 @fiscal_period_end,  50,  @curr_precision, @value OUTPUT  IF ( @return_status != 0 )  RETURN @return_status 
 IF isnull(@value,0.0) = 0.0  SELECT @depreciation_val = isnull(@value,0.0)  ELSE 
 SELECT @depreciation_val = -(isnull(@value,0.0))  SELECT @depr_total_val = @depr_total_val - isnull(@value,0.0) 
  EXEC @return_status = amGetValueRep_sp  @co_asset_book_id,  1,  @fiscal_period_start, 
 @fiscal_period_end,  60,  @curr_precision, @value OUTPUT  IF ( @return_status != 0 )  RETURN @return_status 
 IF isnull(@value,0.0) = 0.0  SELECT @depreciation_val = @depreciation_val + isnull(@value,0.0) 
 ELSE  SELECT @depreciation_val = @depreciation_val - (isnull(@value,0.0))  SELECT @depr_total_val = @depr_total_val - isnull(@value,0.0) 
  EXEC @return_status = amGetValueRep_sp  @co_asset_book_id,  1,  @fiscal_period_start, 
 @fiscal_period_end,  70,  @curr_precision, @value OUTPUT  IF ( @return_status != 0 )  RETURN @return_status 
 IF isnull(@value, 0.0) = 0.0  SELECT @disposition_val = @disposition_val + isnull(@value, 0.0) 
 ELSE  SELECT @disposition_val = @disposition_val - (isnull(@value, 0.0))  SELECT @depr_total_val = @depr_total_val - isnull(@value,0.0) 
  IF isnull(@accum_depr, 0.0) = 0.0  SELECT @accum_depr = isnull(@accum_depr, 0.0) 
 ELSE  SELECT @accum_depr = -(isnull(@accum_depr, 0.0))   

UPDATE #ampdrep  SET start_value = ISNULL(@accum_depr,0.0), 
 addition = ISNULL(@addition_val,0.0),  revaluation = ISNULL(@revaluation_val,0.0), 
 improvements = ISNULL(@improvement_val,0.0),  adjustment = ISNULL(@adjustment_val,0.0), 
 impairment = ISNULL(@impairment_val,0.0),  disposition = ISNULL(@disposition_val,0.0), 
 depreciation = ISNULL(@depreciation_val,0.0),  end_value = ISNULL(@depr_total_val,0.0) 
 WHERE co_asset_id = @co_asset_id  AND account_type = 1  


SELECT @return_status = @@error 
 IF ( @return_status != 0 )  RETURN @return_status  END    

UPDATE #ampdrep  
SET start_value = ISNULL(@cost, 0.0) - ISNULL(@accum_depr, 0.0), 
 end_value = ISNULL(@asset_total_val, 0.0) - ISNULL(@depr_total_val, 0.0)  
WHERE co_asset_id = @co_asset_id 
 AND account_type = 2  

DELETE #counter1  
SET ROWCOUNT 0 
END     
 
 UPDATE #ampdrep 
 SET #ampdrep.asset_ctrl_num = ISNULL(b.asset_ctrl_num,''), 
     #ampdrep.asset_description = ISNULL(b.asset_description,''),
	 #ampdrep.asset_type_code = ISNULL(b.asset_type_code,'')			
 FROM #ampdrep,  amasset b 
 WHERE #ampdrep.co_asset_id = b.co_asset_id           

 
 EXEC @return_status = amGetString_sp 
 21,  @total_string OUTPUT IF @return_status <> 0  RETURN @return_status  


/* insert subtotal lines for each of the asset types */

/* Cost */
 INSERT #ampdrep 
(
 type_code_id, asset_type_code,
 asset_ctrl_num,  co_asset_id,  asset_description,  account_type,  start_value,  addition, 
 improvements,  revaluation,  adjustment,  impairment,  disposition,  depreciation, 
 end_value 
)
SELECT  1, asset_type_code,
  asset_type_code + ' Totals',  0,  ' ',  0,  ISNULL(SUM(start_value), 0.0),  ISNULL(SUM(addition), 0.0), 
 ISNULL(SUM(improvements), 0.0),  ISNULL(SUM(revaluation), 0.0),  ISNULL(SUM(adjustment), 0.0), 
 ISNULL(SUM(impairment), 0.0),  ISNULL(SUM(disposition), 0.0),  ISNULL(SUM(depreciation), 0.0), 
 ISNULL(SUM(end_value), 0.0) 
 FROM #ampdrep 
 WHERE account_type = 0
 GROUP BY asset_type_code


/* Accum Deprn */
 INSERT #ampdrep 
(
 type_code_id, asset_type_code,
 asset_ctrl_num,  co_asset_id,  asset_description,  account_type,  start_value,  addition, 
 improvements,  revaluation,  adjustment,  impairment,  disposition,  depreciation, 
 end_value 
)
SELECT  1, asset_type_code,
  asset_type_code + ' Totals',  0,  ' ',  1,  ISNULL(SUM(start_value), 0.0),  ISNULL(SUM(addition), 0.0), 
 ISNULL(SUM(improvements), 0.0),  ISNULL(SUM(revaluation), 0.0),  ISNULL(SUM(adjustment), 0.0), 
 ISNULL(SUM(impairment), 0.0),  ISNULL(SUM(disposition), 0.0),  ISNULL(SUM(depreciation), 0.0), 
 ISNULL(SUM(end_value), 0.0) 
 FROM #ampdrep 
 WHERE account_type = 1  
 GROUP BY asset_type_code

/* WDV */
 INSERT #ampdrep 
(
 type_code_id, asset_type_code,
 asset_ctrl_num,  co_asset_id,  asset_description,  account_type,  start_value,  addition, 
 improvements,  revaluation,  adjustment,  impairment,  disposition,  depreciation, 
 end_value 
)
SELECT  1, asset_type_code,
  asset_type_code + ' Totals',  0,  ' ',  2,  ISNULL(SUM(start_value), 0.0),  0.0,  0.0, 
 0.0,  0.0,  0.0,  0.0,  0.0,  ISNULL(SUM(end_value),0.0) 
 FROM #ampdrep 
 WHERE account_type = 2 
 GROUP BY asset_type_code

 
 /* cost */
 INSERT #ampdrep 
(type_code_id, asset_type_code, type_description,
 asset_ctrl_num,  co_asset_id,  asset_description,  account_type,  start_value,  addition, 
 improvements,  revaluation,  adjustment,  impairment,  disposition,  depreciation, 
 end_value 
)

SELECT  999, 'zzzzzzzzzz', 'REPORT TOTALS',
 '',  0,  ' ',  0,  ISNULL(SUM(start_value), 0.0),  ISNULL(SUM(addition), 0.0), 
 ISNULL(SUM(improvements), 0.0),  ISNULL(SUM(revaluation), 0.0),  ISNULL(SUM(adjustment), 0.0), 
 ISNULL(SUM(impairment), 0.0),  ISNULL(SUM(disposition), 0.0),  ISNULL(SUM(depreciation), 0.0), 
 ISNULL(SUM(end_value), 0.0) 
 FROM #ampdrep 
 WHERE account_type = 0  
 AND   type_code_id <> 1
 

 /* accum depr */
 INSERT #ampdrep 
(type_code_id , asset_type_code, type_description,
 asset_ctrl_num,  co_asset_id,  asset_description,  account_type,  start_value,  addition, 
 improvements,  revaluation,  adjustment,  impairment,  disposition,  depreciation, 
 end_value 
)

SELECT  999, 'zzzzzzzzzz', 'REPORT TOTALS',
  '',  0,  ' ',  1,  ISNULL(SUM(start_value), 0.0),  ISNULL(SUM(addition), 0.0), 
 ISNULL(SUM(improvements), 0.0),  ISNULL(SUM(revaluation), 0.0),  ISNULL(SUM(adjustment), 0.0), 
 ISNULL(SUM(impairment), 0.0),  ISNULL(SUM(disposition), 0.0),  ISNULL(SUM(depreciation), 0.0), 
 ISNULL(SUM(end_value), 0.0) 
 FROM #ampdrep 
 WHERE account_type = 1  
 AND   type_code_id <> 1
 
  /* WDV */
 INSERT #ampdrep 
(type_code_id, asset_type_code, type_description,
 asset_ctrl_num,  co_asset_id,  asset_description,  account_type,  start_value,  addition, 
 improvements,  revaluation,  adjustment,  impairment,  disposition,  depreciation, 
 end_value 
)
SELECT  999, 'zzzzzzzzzz','REPORT TOTALS',
 '' ,  0,  ' ',  2,  ISNULL(SUM(start_value), 0.0),  0.0,  0.0, 
 0.0,  0.0,  0.0,  0.0,  0.0,  ISNULL(SUM(end_value),0.0) 
 FROM #ampdrep 
 WHERE account_type = 2 
 AND   type_code_id <> 1

UPDATE #ampdrep
SET #ampdrep.type_description = UPPER(asset_type_description)
FROM #ampdrep a, amasttyp b
WHERE a.asset_type_code = b.asset_type_code
 
UPDATE #ampdrep
SET    type_code_id = 0
WHERE  type_code_id not in (1,999)

UPDATE #ampdrep
SET #ampdrep.org_id = ISNULL(b.org_id,""), 
    #ampdrep.region_id = ISNULL(dbo.IBGetParent_fn (b.org_id),"")
FROM #ampdrep,  amasset b, amOrganization_vw o,region_vw r 
WHERE #ampdrep.co_asset_id = b.co_asset_id
AND	b.org_id			= o.org_id
AND     b.org_id 			= r.org_id 


INSERT INTO #ammovement (type_code_id,
			asset_ctrl_num, asset_description, account_type,
 	 		asset_type_code, type_description, 
			start_value, addition, improvement, revaluation, adjustment, impairment,
			disposition, depreciation, end_value, org_id, region_id
			)
	SELECT type_code_id, asset_ctrl_num, asset_description, account_type,
 	 		asset_type_code, type_description, 
			start_value, addition, improvements, revaluation, adjustment, impairment,
			disposition, depreciation, end_value, org_id , region_id
 	 FROM #ampdrep 
 ORDER BY type_code_id, asset_type_code, asset_ctrl_num,co_asset_id,account_type  

 
DROP TABLE #ampdrep 
IF ( @debug_level > 1 ) SELECT 'tmp/ampdpdrp.sp' + ', line ' + STR( 957, 5 ) + ' -- EXIT: ' 
RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[ammovementreport_sp] TO [public]
GO
