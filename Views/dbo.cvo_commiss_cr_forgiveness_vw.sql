SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[cvo_commiss_cr_forgiveness_vw] AS 

/*
DROP TABLE dbo.cvo_sc_ra_forgiveness;
CREATE TABLE cvo_sc_ra_forgiveness
    (
        Salesperson VARCHAR(8) ,
        Territory VARCHAR(8) ,
        Cust_code VARCHAR(8) ,
        Order_no INT ,
		Ext INT,
        Invoice_no VARCHAR(10) ,
        InvoiceDate DATETIME ,
        Amount FLOAT(8) ,
		comm_pct decimal(5,2),
		comm_amt float(8),
        RA_amount FLOAT NULL ,
        pom_amount FLOAT NULL ,
        forgive_me VARCHAR(3) NULL,
		id  INT IDENTITY(1,1) 
    );

	GRANT ALL ON dbo.cvo_sc_ra_forgiveness TO PUBLIC;
*/
    
	SELECT cbwt.Salesperson ,
           cbwt.salesperson_name ,
           cbwt.Territory ,
           cbwt.Cust_code ,
           cbwt.Ship_to ,
           cbwt.Name ,
           cbwt.Order_no ,
           cbwt.Ext ,
           cbwt.Invoice_no ,
           cbwt.invoicedate_dt InvoiceDate ,
           cbwt.dateshipped_dt DateShipped ,
           cbwt.OrderType ,
           cbwt.type ,
           cbwt.Net_Sales ,
           cbwt.Brand ,
           cbwt.Amount ,
           cbwt.Comm_pct ,
           cbwt.Comm_amt ,
           cbwt.HireDate ,
           cbwt.draw_amount ,
           cbwt.fiscal_period ,
		   ISNULL(srf.RA_amount,ipa.RA_amount) RA_amount,
		   ISNULL(srf.pom_amount,ipa.pom_amount) pom_amount,
		   srf.forgive_me,
		   cbwt.id bldr_id
	FROM dbo.cvo_commission_bldr_work_tbl AS cbwt 
	LEFT OUTER join 
		(SELECT   ipa.order_no ,
			 ipa.order_ext ,
			 -SUM(ipa.ExtPrice) RA_amount ,
			 -SUM(CASE WHEN ISNULL(field_28, GETDATE()) < ipa.date_shipped THEN
						  ipa.ExtPrice
					  ELSE 0
				 END) AS pom_amount
	FROM     dbo.cvo_item_pricing_analysis AS ipa
			 JOIN inv_master_add ia ON ia.part_no = ipa.part_no
	WHERE    ipa.return_code = '06-13'
	GROUP BY ipa.order_no ,
			 ipa.order_ext
	) ipa ON ipa.order_no = cbwt.Order_no  AND ipa.order_ext = cbwt.Ext
	
	LEFT OUTER JOIN dbo.cvo_sc_ra_forgiveness AS srf
	ON srf.Invoice_no = cbwt.Invoice_no AND srf.InvoiceDate = cbwt.InvoiceDate_dt
	AND srf.Order_no = cbwt.Order_no
	WHERE cbwt.type = 'crd' AND cbwt.OrderType = 'st' AND 0 <> ISNULL(ipa.RA_amount,0) AND 0 <> ISNULL(ipa.pom_amount,0)
	-- AND 6 > DATEDIFF(MONTH, cbwt.HireDate, cbwt.invoicedate_dt)
	;



GO
GRANT SELECT ON  [dbo].[cvo_commiss_cr_forgiveness_vw] TO [public]
GO
