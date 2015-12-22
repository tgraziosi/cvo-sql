SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Tine Graziosi
-- Create date: 3/17/2014
-- Description:	Debit Promo Log
/*
 EXEC CVO_DEBIT_PROMO_LOG_SP '1/1/2014','4/1/2014'
*/
-- =============================================
CREATE PROCEDURE [dbo].[cvo_debit_promo_log_sp] 
	-- Add the parameters for the stored procedure here
	@startdate datetime = null,
	@enddate datetime = null

    
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- SELECT @version, @startdate, @enddate, @HDR_REC_ID
	
    declare @version int
    select @version = 0
	
	if @version = 0  -- Header level
	begin

        declare @last_hdr_id int, 
        @orig_order int, 
        @orig_ext int,
        @orig_inv varchar(16), 
        @orig_ord_status varchar(1),
        @orig_ship_to varchar(10),
        @orig_slp varchar(10),
        @dh_start_date datetime,
        @customer_code varchar(10),
        @debit_promo_id varchar(20),
        @debit_promo_level varchar(30),
        @invoice_date datetime

        -- drop table #dh

        select 
            dh.hdr_rec_id,
            dh.customer_code, 
            space(10) as ship_to,
            ar.customer_name,
            ar.contact_name,
            ar.contact_phone,
            space(10) as slp,
            dh.debit_promo_id,
            dh.debit_promo_level, 
            dh.drawdown_promo_id,
            dh.drawdown_promo_level,
            0 as orig_order,
            0 as orig_ext,
            '' as orig_status, 
            space(16) as orig_inv,
            cast('1/1/1900' as datetime) as invoice_date,
            dh.start_date,
            dh.expiry_date,
            dh.amount,
            dh.balance,
            dh.available, dh.open_orders
        into #dh
        from cvo_debit_promo_customer_hdr dh 
        -- left outer join cvo_debit_promo_customer_det dd on dd.hdr_rec_id = dh.hdr_rec_id
        inner join arcust ar on ar.customer_code = dh.customer_code
        WHERE DH.START_DATE BETWEEN @STARTDATE AND @ENDDATE

        select @last_hdr_id = min(hdr_rec_id) from #dh

        select @debit_promo_id = debit_promo_id, @debit_promo_level = debit_promo_level,
                @customer_code = customer_code, @dh_start_date = start_date
          from #dh where hdr_rec_id = @last_hdr_id

        while @last_hdr_id is not null
        begin

            select @orig_order = min(co.order_no) 
            from cvo_orders_all co inner join orders o on o.order_no = co.order_no and o.ext = co.ext 
            where 1=1
        -- and o.date_entered >= @dh_start_date 
            and co.promo_id = @debit_promo_id 
            and co.promo_level = @debit_promo_level 
            and status <> 'v' and type = 'i'
            and o.cust_code = @customer_code
            
            select @orig_ext = min(ext) from orders 
                where order_no = @orig_order
            and status <> 'v' and type = 'i'
            
            select 
                @orig_ord_status = status, 
                @orig_slp = salesperson, 
                @orig_ship_to = ship_to,
                @invoice_date = invoice_date
                 from orders
                where order_no = @orig_order and status <> 'v' and ext = @orig_ext
                
            select @orig_inv = doc_ctrl_num from orders_invoice oi 
                        where order_no = @orig_order and order_ext = @orig_ext

            --sp_help orders
            

            update #dh set orig_inv = isnull(@orig_inv,''), 
                          invoice_date = isnull(@invoice_date,0),
                          orig_order = isnull(@orig_order,0),
                          orig_ext = isnull(@orig_ext,0),
                          orig_status = isnull(@orig_ord_status,''),
                          slp = isnull(@orig_slp,''),
                          ship_to = isnull(@orig_ship_to,'')
                       where hdr_rec_id = @last_hdr_id
                       
            select @last_hdr_id = min(hdr_rec_id) from #dh where hdr_rec_id > @last_hdr_id
            select @debit_promo_id = debit_promo_id, @debit_promo_level = debit_promo_level,
                    @customer_code = customer_code, @dh_start_date = start_date
              from #dh where hdr_rec_id = @last_hdr_id

        end -- while loop

        select * from #dh
        
        end -- Header info
        
        if @version = 1 -- Details.  This code is embedded in the ssrs report.  Store here for backup
        begin
        
            SELECT distinct dd.trx_ctrl_num AS Crm_trx_num, 
            arcrm.doc_ctrl_num crm_doc_ctrl_num,
            oi.trx_ctrl_num Inv_trx_ctrl_num, 
            arinv.doc_ctrl_num inv_doc_ctrl_num,
            arcrm.amt_net,
            arcrm.amt_freight,
            arcrm.amt_tax,
            dd.hdr_rec_id, 
            dd.order_no, 
            dd.ext, 
            dd.posted, 
            dbo.adm_format_pltdate_f(arcrm.date_applied) AS date_applied
            FROM CVO_debit_promo_customer_det AS dd
            INNER JOIN ord_list ol ON ol.order_no = dd.order_no AND ol.order_ext = dd.ext AND ol.line_no = dd.line_no 
            LEFT OUTER JOIN orders_invoice oi ON oi.order_no = dd.order_no AND oi.order_ext = dd.ext 
            LEFT OUTER JOIN artrx AS arinv ON oi.trx_ctrl_num = arinv.trx_ctrl_num
            LEFT OUTER JOIN artrx AS arcrm ON dd.trx_ctrl_num = arcrm.trx_ctrl_num

                    
        end -- details
        
 END
GO
GRANT EXECUTE ON  [dbo].[cvo_debit_promo_log_sp] TO [public]
GO
