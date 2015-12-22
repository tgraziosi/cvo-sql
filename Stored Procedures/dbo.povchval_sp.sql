SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[povchval_sp] @process_ctrl_num varchar(16) 

AS
DECLARE @result int


SELECT @result = 0

IF OBJECT_ID('tempdb..#sum_match') IS NOT NULL 
	   DROP TABLE #sum_match

-- first sum amt
	     
SELECT
    ( SIGN( SUM(dtl.amt_discount) ) * ROUND( ABS( SUM(dtl.amt_discount) ) + 0.0000001, 2) )  sum_amt_discount,
    ( SIGN( SUM(dtl.amt_freight) ) * ROUND( ABS( SUM(dtl.amt_freight) ) + 0.0000001, 2) ) sum_amt_freight,
    ( SIGN( SUM(dtl.amt_misc) ) * ROUND( ABS( SUM(dtl.amt_misc) ) + 0.0000001, 2) ) sum_amt_misc,
    ( SIGN( SUM(dtl.amt_tax) ) * ROUND( ABS( SUM(dtl.amt_tax) ) + 0.0000001, 2) ) sum_amt_tax,
    dtl.match_ctrl_num
    INTO
    #sum_match
 FROM #epmchdtl_val dtl , #epmchhdr_range mt
     WHERE dtl.match_ctrl_num = mt.match_ctrl_num 
      AND     mt.process_ctrl_num = @process_ctrl_num
     GROUP BY dtl.match_ctrl_num        
     
-- Validate amt to the header   

-- Discount amount does not equal the distribution of discount on the line items.
-- 250
IF (SELECT err_type FROM epedterr WHERE err_code = 250) = 0
BEGIN

SELECT @result = 100  
    FROM #sum_match dtl, #epmchhdr_range mt
    WHERE dtl.match_ctrl_num = mt.match_ctrl_num
    AND mt.process_ctrl_num = @process_ctrl_num
    AND ( dtl.sum_amt_discount <> mt.amt_discount )
    

END

-- Tax amount does not equal the distribution of tax on the line items.
-- 280
IF (SELECT err_type FROM epedterr WHERE err_code = 280) = 0
BEGIN

SELECT @result = 100  
    FROM #sum_match dtl, #epmchhdr_range mt
    WHERE dtl.match_ctrl_num = mt.match_ctrl_num
    AND mt.process_ctrl_num = @process_ctrl_num
    AND ( dtl.sum_amt_tax <> mt.amt_tax )

END

-- Freight amount does not equal the distribution of freight on the line items.
-- 300
IF (SELECT err_type FROM epedterr WHERE err_code = 300) = 0
BEGIN

SELECT @result = 100  
    FROM #sum_match dtl, #epmchhdr_range mt
    WHERE dtl.match_ctrl_num = mt.match_ctrl_num
    AND mt.process_ctrl_num = @process_ctrl_num
    AND ( dtl.sum_amt_freight <> mt.amt_freight )

END

-- Miscellaneous amount does not equal the distribution of miscellaneous on the line items.
-- 320
IF (SELECT err_type FROM epedterr WHERE err_code = 320) = 0
BEGIN

SELECT @result = 100  
    FROM #sum_match dtl, #epmchhdr_range mt
    WHERE dtl.match_ctrl_num = mt.match_ctrl_num
    AND mt.process_ctrl_num = @process_ctrl_num
    AND ( dtl.sum_amt_misc <> mt.amt_misc )
        
END


 IF OBJECT_ID('tempdb..#sum_match') IS NOT NULL 
	   DROP TABLE #sum_match

 IF @result > 0  
 BEGIN 
    RETURN 100
 END  


	
RETURN
GO
GRANT EXECUTE ON  [dbo].[povchval_sp] TO [public]
GO
