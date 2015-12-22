SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[cvo_auto_posting_routine]  AS 
BEGIN
SET NOCOUNT ON

DECLARE @order_no int
DECLARE @order_ext int
DECLARE @load_no int
DECLARE @rowcount int
DECLARE @PSQL_GLPOST_MTH char(1)
DECLARE @ARPOST_BATCH_SIZE int
DECLARE @temp varchar(255)
DECLARE @selected_orders int
DECLARE @ICV_POST char(1)
DECLARE @result int
DECLARE @batch varchar(16)
DECLARE @ICVERIFY char(1)
DECLARE @err1 int
DECLARE @order_count int
DECLARE @body varchar (500)
DECLARE @orders_recovery int
DECLARE @shipped_count int
DECLARE @cr_order_count int
DECLARE @cr_orders_recovery int
DECLARE @cr_shipped_count int

CREATE TABLE #ewerror(    module_id smallint,	err_code  int,
	info1 char(32),info2 char(32),	infoint int,	infofloat float,
	flag1 smallint,	trx_ctrl_num char(16),sequence_id int,
	source_ctrl_num char(16),	extra int)
CREATE TABLE #arvalchg(	trx_ctrl_num    varchar(16),
	doc_ctrl_num    varchar(16),
	doc_desc	varchar(40),apply_to_num    varchar(16),
	apply_trx_type  smallint,
	order_ctrl_num  varchar(16),	batch_code      varchar(16),
	trx_type        smallint,	date_entered    int,	date_applied    int,
	date_doc        int,	date_shipped    int,date_required   int,
	date_due        int,	date_aging      int,	customer_code   varchar(8),
	ship_to_code    varchar(8),salesperson_code        varchar(8),
	territory_code  varchar(8),comment_code    varchar(8),fob_code        varchar(8),
	freight_code    varchar(8),	terms_code      varchar(8),	fin_chg_code    varchar(8),
	price_code      varchar(8),dest_zone_code  varchar(8),	posting_code    varchar(8),
	recurring_flag  smallint,	recurring_code  varchar(8),tax_code        varchar(8),
	cust_po_num     varchar(20),	total_weight    float,	amt_gross       float,
	amt_freight     float,	amt_tax float,	amt_tax_included	float,
	amt_discount    float,	amt_net float,amt_paid        float,
	amt_due float,	amt_cost        float,	amt_profit      float,
	next_serial_id  smallint,printed_flag    smallint,	posted_flag     smallint,
	hold_flag       smallint,	hold_desc	varchar(40),user_id smallint,
	customer_addr1	varchar(40),	customer_addr2	varchar(40),
	customer_addr3	varchar(40),customer_addr4	varchar(40),
	customer_addr5	varchar(40),	customer_addr6	varchar(40),
	ship_to_addr1	varchar(40),ship_to_addr2	varchar(40),
	ship_to_addr3	varchar(40),	ship_to_addr4	varchar(40),
	ship_to_addr5	varchar(40),ship_to_addr6	varchar(40),
	attention_name	varchar(40),	attention_phone	varchar(30),
	amt_rem_rev     float,amt_rem_tax     float,
	date_recurring  int,	location_code   varchar(8),
	process_group_num       varchar(16) NULL,source_trx_ctrl_num     varchar(16) NULL,
	source_trx_type smallint NULL,	amt_discount_taken      float NULL,
	amt_write_off_given     float NULL,	nat_cur_code    varchar(8),
    	rate_type_home  varchar(8), rate_type_oper  varchar(8),
	rate_home       float, 	rate_oper       float,
	temp_flag	smallint	NULL,
	org_id			varchar(30) NULL, --added for 7.3.6 dmoon
	interbranch_flag		int NULL, --added for 7.3.6 SP1 dmoon - problem with ARINSrcInsertValTables_SP
	temp_flag2		int NULL)--added for 7.3.6 dmoon

--Post Shipments from Group Orders

CREATE TABLE #temp_load
	( load_no int NOT NULL )


/*insert all orders with a status of R */
INSERT into #temp_load
SELECT 	load_no
FROM  load_master
WHERE status = 'R'

/* Get Gl posting method */
select @PSQL_GLPOST_MTH = value_str from config where flag = 'PSQL_GLPOST_MTH'


/* get the ARpost batch size */
select @temp = value_str from config where flag = 'ARPOST_BATCH_SIZE'
select @ARPOST_BATCH_SIZE = CAST( @temp AS int )

/* reset the arbatch size if needed */
select @selected_orders = count(*) from #temp_load

--
select @PSQL_GLPOST_MTH
select @temp
select @ARPOST_BATCH_SIZE
select @selected_orders
--

if @selected_orders > @ARPOST_BATCH_SIZE and @ARPOST_BATCH_SIZE > 0 
BEGIN
	select @ARPOST_BATCH_SIZE = @selected_orders
END


/* looping through each order now */
SELECT @load_no = 0
WHILE (42=42)
BEGIN

	SET ROWCOUNT 1
	SELECT @load_no = load_no
	FROM #temp_load
	WHERE load_no > @load_no
	ORDER BY load_no

	SELECT @rowcount = @@rowcount
	SET ROWCOUNT 0
	IF @rowcount = 0
		BREAK


	/* lets get the next batch number */
	exec cvo_fs_next_batch 'ADM AR Transactions', 'sa', 18000, @batch out
	

	UPDATE load_master
	SET status = 'S',
	    process_ctrl_num = @batch 
	WHERE load_no = @load_no


	
	exec dbo.fs_post_ar_group 'sa' , @batch
 



END --  loop
DROP TABLE #temp_load
TRUNCATE TABLE #ewerror
TRUNCATE TABLE #arvalchg


--Post sales orders


/* Create a temp table to hold all orders to be posted */
CREATE TABLE #temp_orders
	( order_no int NOT NULL,
	  order_ext int NOT NULL )


/*insert all orders with a status of R */
INSERT into #temp_orders
SELECT 	order_no,
	ext
FROM  orders_all
WHERE status = 'R'
AND type = 'I' and load_no = 0	
and process_ctrl_num = ''
--and order_no  > 3047950
--and order_no <= 3062955
order by order_no


SELECT @order_count = (SELECT 	count(order_no)
FROM  orders_all
WHERE status = 'R'
AND type = 'I' and load_no = 0	
and process_ctrl_num = '')


/* Get Gl posting method */
select @PSQL_GLPOST_MTH = value_str from config where flag = 'PSQL_GLPOST_MTH'


/* get the ARpost batch size */
select @temp = value_str from config where flag = 'ARPOST_BATCH_SIZE'
select @ARPOST_BATCH_SIZE = CAST( @temp AS int )

/* reset the arbatch size if needed */
select @selected_orders = count(*) from #temp_orders

if @selected_orders > @ARPOST_BATCH_SIZE and @ARPOST_BATCH_SIZE > 0 
BEGIN
	select @ARPOST_BATCH_SIZE = @selected_orders
END


/* looping through each order now */
SELECT @order_no = 0, @order_ext = 0 
WHILE (42=42)
BEGIN

	SET ROWCOUNT 1
	SELECT @order_no = order_no, @order_ext = order_ext
	FROM #temp_orders
	WHERE order_no > @Order_no
	ORDER BY order_no

	SELECT @rowcount = @@rowcount
	SET ROWCOUNT 0
	IF @rowcount = 0
		BREAK


	/* lets get the next batch number */
	exec cvo_fs_next_batch 'ADM AR Transactions', 'sa', 18000, @batch out
	

	UPDATE orders_all
	SET process_ctrl_num = @batch 
	WHERE order_no = @order_no
	AND   ext = @order_ext

	
	exec dbo.fs_post_ar 'sa' , @batch, @err1 OUT




END --  loop
TRUNCATE TABLE #temp_orders


-- credit returns



/* Create a temp table to hold all orders to be posted */
/*
CREATE TABLE #temp_orders
	( order_no int NOT NULL,
	  order_ext int NOT NULL )
*/

/*insert all orders with a status of R */
INSERT into #temp_orders
SELECT 	order_no,
	ext
FROM  orders_all
WHERE status = 'R'
AND type = 'C' and load_no = 0	
and process_ctrl_num = ''
--and order_no  > 3047950
--and order_no <= 3062955
order by order_no


SELECT @cr_order_count = (SELECT 	count(order_no)
FROM  orders_all
WHERE status = 'R'
AND type = 'C' and load_no = 0	
and process_ctrl_num = '')


/* Get Gl posting method */
select @PSQL_GLPOST_MTH = value_str from config where flag = 'PSQL_GLPOST_MTH'


/* get the ARpost batch size */
select @temp = value_str from config where flag = 'ARPOST_BATCH_SIZE'
select @ARPOST_BATCH_SIZE = CAST( @temp AS int )

/* reset the arbatch size if needed */
select @selected_orders = count(*) from #temp_orders

if @selected_orders > @ARPOST_BATCH_SIZE and @ARPOST_BATCH_SIZE > 0 
BEGIN
	select @ARPOST_BATCH_SIZE = @selected_orders
END


/* looping through each order now */
SELECT @order_no = 0, @order_ext = 0 
WHILE (42=42)
BEGIN

	SET ROWCOUNT 1
	SELECT @order_no = order_no, @order_ext = order_ext
	FROM #temp_orders
	WHERE order_no > @Order_no
	ORDER BY order_no

	SELECT @rowcount = @@rowcount
	SET ROWCOUNT 0
	IF @rowcount = 0
		BREAK


	/* lets get the next batch number */
	exec cvo_fs_next_batch 'ADM AR Transactions', 'sa', 18000, @batch out
	

	UPDATE orders_all
	SET process_ctrl_num = @batch 
	WHERE order_no = @order_no
	AND   ext = @order_ext

	
	exec dbo.fs_post_ar 'sa' , @batch, @err1 OUT




END --  loop
DROP TABLE #temp_orders


-- end credit returns


select @orders_recovery = (SELECT 	count(order_no)
							FROM  orders_all
							WHERE status = 'R'
							AND type = 'I' and load_no = 0	
							and process_ctrl_num <> '')

select @cr_orders_recovery = (SELECT 	count(order_no)
							FROM  orders_all
							WHERE status = 'R'
							AND type = 'C' and load_no = 0	
							and process_ctrl_num <> '')

select @shipped_count = (select count(order_no) from orders_all where status = 'S' and type = 'I')
select @cr_shipped_count = (select count(order_no) from orders_all where status = 'S' and type = 'C')

-- assemble body

select @body = 'Prior to posting orders to be posted = '  + cast (@order_count as varchar (12)) + char(13) +
'Prior to posting credit returns to be posted = '  + cast (@cr_order_count as varchar (12)) + char(13) +
'After Posting total orders in Shipped status (S) = ' + cast (@shipped_count as varchar (12)) + char(13) +
'After Posting total credit returns in Shipped status (S) = ' + cast (@cr_shipped_count as varchar (12)) + char(13) +
'After Posting total orders in recovery = ' + cast (@orders_recovery as varchar (12)) + char(13) +
'After Posting total credit returns in recovery = ' + cast (@cr_orders_recovery as varchar (12))



	EXEC msdb.dbo.sp_send_dbmail @profile_name = 'WMS_1'
	  , @recipients = 'tgraziosi@cvoptical.com'
--	  , @recipients = 'dmoon@epicor.com'
----	  , @blind_copy_recipients = 'customer_service@XXXXX'
	  , @subject = 'The Shipment Posting Job Has Completed!!'
	  , @body = @body
 

END


-- execute cvo_auto_posting_routine
GO
GRANT EXECUTE ON  [dbo].[cvo_auto_posting_routine] TO [public]
GO
