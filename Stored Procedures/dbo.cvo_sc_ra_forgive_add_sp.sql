SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_sc_ra_forgive_add_sp] @bldr_ids varchar(5000)
AS

-- EXEC dbo.cvo_sc_ra_forgive_add_sp @bldr_ids = '894978,123456' -- varchar(5000)

BEGIN

SET NOCOUNT ON
SET ANSI_WARNINGS OFF

/*
SELECT srf.bldr_id ,
       *
FROM   dbo.cvo_commiss_cr_forgiveness_vw AS srf
WHERE  srf.Territory = '40431'
       AND srf.Salesperson = 'lyonto'
       AND 6 > DATEDIFF(MONTH, HireDate, srf.InvoiceDate);

DECLARE @bldr_ids VARCHAR(5000);
SELECT @bldr_ids = '777514,777648,778076,778380,778696,779282,779294,779372,833892,896494';
*/

CREATE TABLE #bldr_id
    (
        bldr_id INT
    );

INSERT INTO #bldr_id ( bldr_id )
            SELECT CAST(ListItem AS INT)
            FROM   dbo.f_comma_list_to_table(@bldr_ids);

INSERT INTO dbo.cvo_sc_ra_forgiveness ( Salesperson ,
                                        Territory ,
                                        Cust_code ,
                                        Order_no ,
                                        Ext ,
                                        Invoice_no ,
                                        InvoiceDate ,
                                        Amount ,
										comm_pct,
										comm_amt,
                                        RA_amount ,
                                        pom_amount ,
                                        forgive_me )
            SELECT cbwt.Salesperson , 
                   cbwt.Territory ,
                   cbwt.Cust_code ,
                   cbwt.Order_no ,
                   cbwt.Ext ,
                   cbwt.Invoice_no ,
                   cbwt.InvoiceDate ,
                   cbwt.Amount ,
				   cbwt.Comm_pct,
				   ROUND(cbwt.comm_pct/100 * pom_amount,2) comm_amt, -- only forgive the pom amount of the RA, not the whole thing.
				   -- cbwt.Comm_amt,
                   RA_amount ,
                   pom_amount ,
                   'Yes'
            FROM   #bldr_id AS bi
                   JOIN dbo.cvo_commiss_cr_forgiveness_vw AS cbwt ON cbwt.bldr_id = bi.bldr_id
            WHERE  NOT EXISTS (   SELECT 1
                                  FROM   dbo.cvo_sc_ra_forgiveness AS srf_OLD
                                  WHERE  srf_OLD.Salesperson = cbwt.Salesperson
                                         AND srf_OLD.Territory = cbwt.Territory
                                         AND srf_OLD.Invoice_no = cbwt.Invoice_no
										 AND srf_old.Order_no = cbwt.Order_no
										 AND srf_old.Amount = cbwt.amount );

										 								 
END

GRANT EXECUTE ON dbo.cvo_sc_ra_forgive_add_sp TO PUBLIC

GO
GRANT EXECUTE ON  [dbo].[cvo_sc_ra_forgive_add_sp] TO [public]
GO
