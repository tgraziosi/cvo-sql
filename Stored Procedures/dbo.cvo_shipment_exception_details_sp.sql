SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_shipment_exception_details_sp] 
@TransactionFromDate DATETIME,
@TransactionToDate datetime
AS  

begin

SET NOCOUNT ON
-- show shipment exeption info for daily activity log
-- exec cvo_shipment_exception_details_sp '6/22/2015','6/22/2015'
/*
DECLARE @transactionfromdate DATETIME, @transactiontodate datetime
SELECT @transactionfromdate = '6/22/2015', @transactiontodate = '6/22/2015'
*/

SELECT  A.cust_code ,
        A.order_no ,
        A.date_entered ,
        A.who_entered ,
        A.status ,
        A.date_shipped ,
        A.ordertype ,
        A.tot_shp_qty ,
        A.back_ord_flag ,
        A.date_sch_ship ,
        A.Cust_type ,
        A.ext ,
        A.timeslot ,
        A.hold_reason ,
        A.ShipComplete ,
        A.FutureShip ,
        A.KeyAccount ,
        A.total_amt_order ,
        A.promo_id ,
        cr.carton_no ,
        cr.carton_status ,
        cr.pack_no ,
        cr.station_id ,
        cr.order_type ,
        cr.carrier_code ,
        cr.ship_to_no ,
        cr.name ,
        cr.last_modified_date ,
        cr.modified_by ,
        cr.salesperson ,
        cr.Territory ,
        td.qty_ord ,
        td.qty_shp ,
        td.qty_alloc ,
        td.qty_picked ,
        td.qty_packed ,
        td.Global_ship_to ,
        td.date_printed,
		tdclog.tdc_timeslot,
		tdclog.data,
		tdclog.tdc_time
FROM    ( SELECT    cust_code ,
                    order_no ,
                    date_entered ,
                    who_entered ,
                    status ,
                    date_shipped ,
                    order_type AS ordertype ,
                    qty_shipped AS tot_shp_qty ,
                    back_ord_flag ,
                    date_sch_ship ,
                    Cust_type ,
                    ext ,
                    CASE WHEN CONVERT(VARCHAR(10), date_entered, 108) <= '15:00:00'
                              AND LEFT(order_type, 2) = 'ST' THEN 'BEFORE3'
                         WHEN CONVERT(VARCHAR(10), date_entered, 108) > '15:00:00'
                              AND LEFT(order_type, 2) = 'ST' THEN 'AFTER3'
                         WHEN CONVERT(VARCHAR(10), date_entered, 108) <= '16:00:00'
                              AND LEFT(order_type, 2) = 'RX' THEN 'BEFORE4'
                         WHEN CONVERT(VARCHAR(10), date_entered, 108) > '16:00:00'
                              AND LEFT(order_type, 2) = 'RX' THEN 'AFTER4'
                         ELSE CONVERT(VARCHAR(10), date_entered, 108)
                    END AS timeslot ,
                    hold_reason ,
                    CASE WHEN back_ord_flag = 1 THEN 'SC'
                         ELSE ''
                    END AS ShipComplete ,
                    CASE WHEN date_sch_ship > date_entered THEN 'FS'
                         ELSE ''
                    END AS FutureShip ,
                    CASE WHEN Cust_type = 'Key Account' THEN 'KA'
                         ELSE ''
                    END AS KeyAccount ,
                    total_amt_order ,
                    promo_id
          FROM      cvo_adord_vw
          WHERE     who_entered <> 'BACKORDR'
                    AND date_entered >= @TransactionFromDate
                    AND date_entered < DATEADD(dd,
                                               DATEDIFF(dd, 0,
                                                        @TransactionToDate)
                                               + 1, 0)
                    AND status IN ( 'N', 'P', 'Q' )
        ) A
        LEFT JOIN cvo_carton_recon_vw cr ON A.order_no = cr.order_no
                                            AND A.ext = cr.order_ext
        LEFT JOIN adord_TDC_vw td ON A.order_no = td.order_no
                                     AND A.ext = td.ext
		LEFT OUTER JOIN
        (
		SELECT a.order_no, a.ext, a.order_type,
		CASE 
		WHEN CONVERT(VARCHAR(10), tran_date, 108) > '15:00:00'
             AND LEFT(order_type, 2) = 'ST' THEN 'AFTER'
        WHEN CONVERT(VARCHAR(10), t.tran_date, 108) > '16:00:00'
             AND LEFT(order_type, 2) = 'RX' THEN 'AFTER'
        ELSE CONVERT(VARCHAR(10), tran_date, 108)
        END AS tdc_timeslot,
		LEFT(t.data,80) data 
		, CONVERT(VARCHAR(10), tran_date, 108) tdc_time
		FROM dbo.tdc_log t
		LEFT JOIN dbo.cvo_adord_vw a ON t.tran_no = a.order_no
                          AND t.tran_ext = a.ext
		WHERE trans='order update' AND t.UserID<>'RX_CONSOLIDATE'
		AND data LIKE '%release%'
		AND t.tran_date >= @transactionfromdate
		AND	CASE 
		WHEN CONVERT(VARCHAR(10), T.tran_date, 108) > '15:00:00'
             AND LEFT(order_type, 2) = 'ST' THEN 'AFTER'
        WHEN CONVERT(VARCHAR(10), t.tran_date, 108) > '16:00:00'
             AND LEFT(order_type, 2) = 'RX' THEN 'AFTER'
        ELSE CONVERT(VARCHAR(10), T.tran_date, 108)
        END = 'AFTER'
		) tdclog ON tdclog.order_no = a.order_no AND tdclog.ext = a.ext

WHERE   timeslot IN ( 'BEFORE3', 'BEFORE4' )
        AND ShipComplete <> 'SC'
        AND FutureShip <> 'FS'
        AND KeyAccount <> 'KA'
        AND A.ext < 1;

END

GRANT ALL ON cvo_shipment_exception_details_sp TO PUBLIC

GO
GRANT EXECUTE ON  [dbo].[cvo_shipment_exception_details_sp] TO [public]
GO
