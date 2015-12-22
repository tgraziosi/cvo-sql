SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
CREATE PROC [dbo].[cvo_ARUPDateCustActivity_bgs_SP]          
                                              
AS  
BEGIN  
	DECLARE @precision_home smallint,  
			@precision_oper smallint  
  
    SELECT  @precision_home = curr_precision  
    FROM    glcurr_vw, glco  
    WHERE   glco.home_currency = glcurr_vw.currency_code  
  
    SELECT  @precision_oper = curr_precision  
    FROM    glcurr_vw, glco  
    WHERE   glco.oper_currency = glcurr_vw.currency_code            
          
    INSERT  #cvo_aractcus  
    SELECT	a.customer_code,   
            ROUND(SUM(SIGN(SIGN(ref_id-1)+1)*ROUND(amount*( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home)), @precision_home),  
            ROUND(SUM(SIGN(SIGN(ref_id-1)+1)*ROUND(amount*( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), @precision_oper)), @precision_oper),  
            ROUND(SUM(SIGN(SIGN(0.5-ref_id)+1)*ROUND(-amount*( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home)), @precision_home),  
            ROUND(SUM(SIGN(SIGN(0.5-ref_id)+1)*ROUND(-amount*( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), @precision_oper)), @precision_oper),  
            0.0, 0.0,     /* amt_inv_unp */  
            0.0, 0.0,     /* amt_on_order */  
            SUM(SIGN(SIGN(2031.5 - trx_type)+1)*SIGN(SIGN(1.5-ref_id)+1)),  
            SUM(SIGN(SIGN(2031.5 - trx_type)+1)*SIGN(paid_flag)*SIGN(SIGN(1.5-ref_id)+1)),  
            SUM(SIGN(SIGN(2031.5 - trx_type)+1)*SIGN(paid_flag)*SIGN(SIGN(1.5-ref_id)+1) * SIGN(SIGN(date_paid - date_due+0.5)+1)),  
            SUM(SIGN(SIGN(2031.5 - trx_type)+1)*(date_paid-date_due)*SIGN(paid_flag) * SIGN(SIGN(date_paid-date_due+0.5)+1)),  
            SUM(SIGN(SIGN(2031.5 - trx_type)+1)*(date_paid-date_doc)*SIGN(paid_flag) * SIGN(SIGN(date_paid-date_doc+0.5)+1)),          
            0, 0, 0  
    FROM    artrxage a (NOLOCK) 
	LEFT JOIN #removed_child rc
	ON		a.customer_code = rc.customer_code
	LEFT JOIN #joined_child jc
	ON		a.customer_code = rc.customer_code
	WHERE	(rc.customer_code IS NOT NULL OR jc.customer_code IS NOT NULL)
	AND		(a.date_doc <= rc.remove_date OR a.date_doc >= jc.start_date)
    GROUP BY a.customer_code    
              
 
END  
GO
GRANT EXECUTE ON  [dbo].[cvo_ARUPDateCustActivity_bgs_SP] TO [public]
GO
