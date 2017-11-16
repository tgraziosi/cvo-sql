SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_sc_ra_forgive_add_promo_sp] @slp VARCHAR(10), @terr VARCHAR(10), @fp VARCHAR(10)
AS 
BEGIN

INSERT dbo.cvo_commission_promo_values ( territory ,
                                         rep_code ,
                                         incentive_amount ,
                                         promo_name ,
                                         date ,
                                         recorded_month ,
                                         comments ,
                                         line_type )

       SELECT   ccfv.Territory ,
                ccfv.Salesperson ,
                -ROUND(SUM(ccfv.Comm_amt), 2) incentive_amt ,
                ccfv.fiscal_period + ' ' + salesperson +  ' - Returns Add Back' ,
                GETDATE() ,
                ccfv.fiscal_period ,
                '$' + CAST(-ROUND(SUM(Comm_amt), 2) AS VARCHAR(10)) + ' '
                + fiscal_period + ' - Returns Add Back' ,
                'Adj/Additional Adj 2'
       FROM     dbo.cvo_commiss_cr_forgiveness_vw AS ccfv
       WHERE    ccfv.Salesperson = @slp
                AND ccfv.Territory = @terr
                AND ccfv.fiscal_period = @fp
                AND ccfv.forgive_me = 'yes'
       GROUP BY ccfv.fiscal_period + ' Returns Add Back' ,
                ccfv.Territory ,
                ccfv.Salesperson ,
                ccfv.fiscal_period;

	END
    
GO
