SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_cust_invoice_log_sp]
    @cust_code VARCHAR(12) = NULL,
    @sdate DATETIME = NULL,
    @edate DATETIME = NULL
AS
BEGIN

    /* 1/11/2019 - Special customer request for 055502 (part of Essilor) to get a invoice log on the 2nd day of each month 
*/

    DECLARE @cust VARCHAR(12),
            @ssdate DATETIME,
            @eedate DATETIME;
    SELECT @cust = @cust_code;
    SELECT @ssdate = @sdate;
    SELECT @eedate = @edate;

    --SELECT @cust = '055502',
    --       @ssdate = '12/1/2018',
    --       @eedate = '12/31/2018';

    SELECT ipa.cust_code,
           ipa.source,
           ipa.doc_ctrl_num Invoice_no,
           ipa.date_applied invoice_date,
           ipa.upc_code,
           ipa.List_Price,
           ROUND(ipa.List_Price - ipa.net_price, 2) discount,
           ipa.net_price,
           ipa.Shipped,
           ipa.ExtPrice,
           CASE
               WHEN ipa.source = 'open' THEN
                   ipa.ordered
               ELSE
                   0
           END AS backorder,
           ipa.order_no,
           ipa.order_ext
    FROM dbo.cvo_item_pricing_analysis AS ipa
    WHERE ipa.cust_code LIKE @cust
          AND ISNULL(ipa.date_applied, ipa.date_entered)
          BETWEEN @ssdate AND @eedate
          AND ipa.Doc_Type = 'i'
          AND ipa.type_code IN ( 'frame', 'sun' )
          AND
          (
              (
                  ipa.source <> 'open'
                  AND ipa.Shipped <> 0
              )
              OR
              (
                  ipa.source = 'open'
                  AND ipa.who_entered = 'backordr'
              )
          );



--SELECT TOP(10) * FROM dbo.cvo_item_pricing_analysis AS ipa WHERE source = 'open' AND ipa.Doc_Type = 'i' AND ipa.date_entered > '12/1/2018'
--ORDER BY ipa.date_entered

END;
GO
GRANT EXECUTE ON  [dbo].[cvo_cust_invoice_log_sp] TO [public]
GO
