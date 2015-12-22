SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[amAdditionsRep_sp] 
(
  /* @asset_ctrl_num1 smControlNumber,     */
/*   @asset_ctrl_num2 smControlNumber,  */
/*   @activity_state smallint,   */
/*   @select_assets tinyint,*/
   @book_code smBookCode,  
   @period_start datetime,
   @period_end datetime
)
AS DECLARE  @rowcount smCounter,  
@return_status smErrorCode,  
@co_asset_id1 smSurrogateKey, 
 @co_asset_id2 smSurrogateKey,  
 @is_imported smLogical,  
 @co_asset_id smSurrogateKey, 
 @co_asset_book_id smSurrogateKey,  
 @asset_first_num smControlNumber,  @asset_secnd_num smControlNumber, 
  @fiscal_period_start smApplyDate,  @fiscal_period_end smApplyDate, 
  @profile_date smApplyDate,
 @company_id 	smCompanyID,
 @accum_depr_on_add smMoneyZero,
 @company_name varchar(30)

/*DELETE FROM anz_amAdditions*/

SELECT  @company_id = company_id,
		@company_name = company_name
FROM    glco

SELECT 	@fiscal_period_start 	= CONVERT(datetime, @period_start)
SELECT 	@fiscal_period_end 		= CONVERT(datetime, @period_end)
SELECT  @profile_date = CONVERT(datetime, @period_start)

/*select @profile_date = DATEADD(dd,(@period_start -(SIGN(@period_start)*693596)),"19000101")		*/
/*select @fiscal_period_start = DATEADD(dd,(@period_start -(SIGN(@period_start)*693596)),"19000101")	*/
/*select @fiscal_period_end = DATEADD(dd,(@period_end -(SIGN(@period_end)*693596)),"19000101")		*/

/*IF @asset_ctrl_num1 in ("<Start>", "") or @asset_ctrl_num1 is null	--mod004
BEGIN  
	SELECT @asset_ctrl_num1 = MIN(asset_ctrl_num)  
	FROM amasset  
	WHERE company_id = @company_id 
END 
IF @asset_ctrl_num2 in ("<End>" ,"") or @asset_ctrl_num2 is null	--mod004
BEGIN  
	SELECT @asset_ctrl_num2 = MAX(asset_ctrl_num) 
 	FROM amasset  
 	WHERE company_id = @company_id 
END */

/*IF @asset_ctrl_num2 >= @asset_ctrl_num1 
BEGIN  SELECT @asset_first_num = @asset_ctrl_num1  SELECT @asset_secnd_num = @asset_ctrl_num2 
END ELSE BEGIN  SELECT @asset_first_num = @asset_ctrl_num2  SELECT @asset_secnd_num = @asset_ctrl_num1 
END  */                  

/*CREATE table #ampdrep 
(
 asset_ctrl_num 	char(17) NULL,  
 co_asset_id 		int NULL,  
 asset_description 	varchar(40) NULL, 
 account_type 		tinyint NULL,  
 asset_type_code	varchar(8) NULL,
 type_description   varchar(40) NULL,
 vendor_description varchar(40) NULL,
 po_ctrl_num		varchar(16) NULL,
 invoice_num		varchar(32) NULL,
 in_service_date	datetime NULL,
 original_cost		float NULL,
 accum_depr_on_add  float NULL,
 total				float NULL
 )*/
 
 
  /*CREATE TABLE #amassets 
(co_asset_id int NOT NULL)*/
 

  /*IF @activity_state = 3	--mod004 from 9 to 3
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
		  AND acquisition_date BETWEEN @fiscal_period_start AND @fiscal_period_end
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
	    AND acquisition_date BETWEEN @fiscal_period_start AND @fiscal_period_end

    	SELECT @rowcount = @@rowcount 
	  END
	END
  ELSE
	BEGIN     
	  IF @select_assets = 0 
	  BEGIN 
	    INSERT INTO #amassets  (  co_asset_id )
	    SELECT  co_asset_id
	    FROM amasset 
	    WHERE company_id = @company_id  
		AND asset_ctrl_num BETWEEN @asset_first_num AND @asset_secnd_num 
	    AND activity_state = @activity_state 
		AND acquisition_date BETWEEN @fiscal_period_start AND @fiscal_period_end	   
	    SELECT @rowcount = @@rowcount 
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
	    AND acquisition_date BETWEEN @fiscal_period_start AND @fiscal_period_end
		SELECT @rowcount = @@rowcount 

	  END
	END*/
	
/*IF @rowcount=0
BEGIN 
  SELECT *
  FROM #ampdrep
  RETURN
END */ 


SELECT co_asset_id,  co_asset_book_id 
INTO #counter1 
FROM amastbk
WHERE book_code = @book_code 
AND co_asset_id IN (SELECT co_asset_id
					FROM #amassets ) 

WHILE 1=1 
BEGIN   
	SET ROWCOUNT 1 
	SELECT  @co_asset_id = co_asset_id,  
			  @co_asset_book_id = co_asset_book_id  
	FROM #counter1 

	IF @@rowcount = 0  
	BEGIN  
		SET ROWCOUNT 0  
		BREAK  
	END    
 

	SELECT 	@accum_depr_on_add = ISNULL(SUM(amount), 0.0) 
	FROM 	amvalues 
	WHERE 	co_asset_book_id = @co_asset_book_id 
	AND 	account_type_id = 1
	AND trx_type = 10
	AND apply_date BETWEEN @fiscal_period_start AND @fiscal_period_end 


	INSERT #ampdrep (co_asset_id, asset_ctrl_num, asset_description, 
			asset_type_code, type_description, vendor_description, po_ctrl_num,
			invoice_num, in_service_date, original_cost, accum_depr_on_add, total,org_id, region_id)
	SELECT distinct @co_asset_id, 
			ISNULL(b.asset_ctrl_num,""), 
			ISNULL(b.asset_description,""),
			ISNULL(b.asset_type_code,""),
			"",
			"",
			"",
			"",
			ISNULL(b.placed_in_service_date,""),
			b.original_cost,
			@accum_depr_on_add,
			b.original_cost - @accum_depr_on_add,
			b.org_id,
			dbo.IBGetParent_fn (b.org_id)
	FROM  amasset b,
	      amOrganization_vw o,
	      region_vw r
 	WHERE b.co_asset_id = @co_asset_id
	AND	b.org_id			= o.org_id
	AND     b.org_id 			= r.org_id 

	

	DELETE #counter1 
	SET ROWCOUNT 0
END    
 
 UPDATE #ampdrep 
 SET  #ampdrep.vendor_description = ISNULL(b.vendor_description,""),
	  #ampdrep.po_ctrl_num = ISNULL(b.po_ctrl_num, ""),
	  #ampdrep.invoice_num = ISNULL(b.invoice_num, "")
 FROM #ampdrep,  amitem b
 WHERE #ampdrep.co_asset_id = b.co_asset_id           



UPDATE #ampdrep
SET #ampdrep.type_description = UPPER(asset_type_description)
FROM #ampdrep, amasttyp b
WHERE #ampdrep.asset_type_code = b.asset_type_code

INSERT INTO #anz_amAdditions (
			asset_ctrl_num, asset_description, 
 	 		asset_type_code, type_description, vendor_description, po_ctrl_num,
			invoice_num, in_service_date, original_cost, accum_depr_on_add, total,
			asset_ctrl_num1, asset_ctrl_num2, 
			book_code, period_start,period_end,company_name,org_id,region_id
			)
SELECT asset_ctrl_num, asset_description, 
 	 		asset_type_code, type_description, vendor_description, po_ctrl_num,
			invoice_num, in_service_date, original_cost, accum_depr_on_add, total,
			'asset1' as asset_ctrl_num1,'asset2' as asset_ctrl_num2, 
			@book_code as book_code, 
			convert(varchar(12), @fiscal_period_start, 3) as period_start,
			convert(varchar(12), @fiscal_period_end, 3) as period_end,
			'company' as company_name,org_id,region_id
 	 		 FROM #ampdrep 
	 ORDER BY asset_type_code, asset_ctrl_num,co_asset_id

 
/*DROP TABLE #ampdrep 
DROP TABLE #amassets */

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amAdditionsRep_sp] TO [public]
GO
