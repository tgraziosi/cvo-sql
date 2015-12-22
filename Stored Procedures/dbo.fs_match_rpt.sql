SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


Create Procedure [dbo].[fs_match_rpt] @batch varchar(16), @sort_by varchar(255) = ''
AS
BEGIN

declare @pos int

if isnull(@sort_by,'') = ''
  set @sort_by = 'match_ctrl_int'

set @sort_by = @sort_by + ' '
set @pos = charindex('inv_rec_date',@sort_by)
if @pos > 0
  select @sort_by = replace(@sort_by, 'inv_rec_date', 'invoice_receive_date')
set @pos = charindex('invoice_date',@sort_by)
if @pos > 0
  select @sort_by = replace(@sort_by, 'invoice_date', 'vendor_invoice_date')
set @pos = charindex('match_no',@sort_by)
if @pos > 0
  select @sort_by = replace(@sort_by, 'match_no', 'match_ctrl_int')

select @sort_by = replace(@sort_by, ' D ', ' Desc ')
select @sort_by = replace(@sort_by, ' A ', ' Asc ')

if charindex('match_ctrl_int',@sort_by) = 0 
  select @sort_by = @sort_by + ', match_ctrl_int'
  
select @sort_by = @sort_by + ', match_line_num'

create table #t1
 (	match_ctrl_int int NOT NULL ,
	vendor_code varchar (12) NOT NULL ,
	vendor_remit_to char (8) NULL ,
	printed_flag smallint NOT NULL ,
	amt_net decimal(20, 8) NOT NULL ,
	amt_discount decimal(20, 8) NOT NULL ,
	amt_tax decimal(20, 8) NOT NULL ,
	amt_freight decimal(20, 8) NOT NULL ,
	amt_misc decimal(20, 8) NOT NULL ,
	amt_due decimal(20, 8) NOT NULL ,
	match_posted_flag smallint NOT NULL ,
	nat_cur_code varchar (8) NULL ,
	amt_tax_included decimal(20, 8) NOT NULL ,
	apply_date datetime NOT NULL ,
	aging_date datetime NOT NULL ,
	due_date datetime NOT NULL ,
	discount_date datetime NOT NULL,	
	invoice_receive_date datetime NOT NULL ,
	vendor_invoice_date datetime NOT NULL ,
	vendor_invoice_no varchar(20) NOT NULL,
	date_match datetime NOT NULL ,
	vendor_name varchar(40) NOT NULL,
	pay_to_name varchar(40) NOT NULL,
	match_line_num int not null ,   
	po_ctrl_num varchar(16) NOT NULL,   
	part_no varchar(30) NULL,   
	item_desc varchar(60) NOT NULL,   
	qty_ordered decimal(20,8) NOT NULL,   
	unit_price decimal(20,8) NOT NULL,   
	curr_cost decimal(20,8) NOT NULL,  
	qty_invoiced decimal(20,8) NOT NULL,   
	adm_vend_all_addr1 varchar(40),   
	adm_vend_all_addr2 varchar(40),   
	adm_vend_all_addr3 varchar(40),
	adm_vend_all_addr4 varchar(40),
	adm_vend_all_addr5 varchar(40),
	adm_vend_all_addr6 varchar(40),
	appayto_addr1 varchar(40),
	appayto_addr2 varchar(40),
	appayto_addr3 varchar(40),
	appayto_addr4 varchar(40),
	appayto_addr5 varchar(40),
	appayto_addr6 varchar(40),
	match_unit_price decimal(20,8) NOT NULL,   
	process_group_num varchar(16) NULL,  
	curr_mask varchar(100) NULL ,
	extended_name varchar(120) null,
	trx_ctrl_num varchar(16) NULL
)

  INSERT INTO #t1
   SELECT adm_pomchchg_all.match_ctrl_int,   
          adm_pomchchg_all.vendor_code,   
          adm_pomchchg_all.vendor_remit_to,   
          adm_pomchchg_all.printed_flag,   
          adm_pomchchg_all.amt_gross,   
          adm_pomchchg_all.amt_discount,   
          adm_pomchchg_all.amt_tax,   
          adm_pomchchg_all.amt_freight,   
          adm_pomchchg_all.amt_misc,   
          adm_pomchchg_all.amt_due,   
          adm_pomchchg_all.match_posted_flag,   
          adm_pomchchg_all.nat_cur_code,   
          adm_pomchchg_all.amt_tax_included,   
          adm_pomchchg_all.apply_date,   
          adm_pomchchg_all.aging_date,   
          adm_pomchchg_all.due_date,   
          adm_pomchchg_all.discount_date,   
          adm_pomchchg_all.invoice_receive_date,   
          adm_pomchchg_all.vendor_invoice_date,   
          adm_pomchchg_all.vendor_invoice_no,   
          adm_pomchchg_all.date_match,   
          adm_vend_all.vendor_name,   
          adm_vend_all.vendor_name,   
          adm_pomchcdt.match_line_num,   
          adm_pomchcdt.po_ctrl_num,   
          adm_pomchcdt.part_no,   
          adm_pomchcdt.item_desc,   
          adm_pomchcdt.qty_ordered,   
          adm_pomchcdt.unit_price,   
          adm_pomchcdt.curr_cost,   
          adm_pomchcdt.qty_invoiced,   
          adm_vend_all.addr1,   
          adm_vend_all.addr2,   
          adm_vend_all.addr3,   
          adm_vend_all.addr4,   
          adm_vend_all.addr5,   
          adm_vend_all.addr6,   
          adm_vend_all.addr1,   
          adm_vend_all.addr2,   
          adm_vend_all.addr3,   
          adm_vend_all.addr4,   
          adm_vend_all.addr5,   
          adm_vend_all.addr6,   
          adm_pomchcdt.match_unit_price,   
          adm_pomchchg_all.process_group_num,  
          glcurr_vw.currency_mask  ,
		  isnull(adm_vend_all.extended_name, adm_vend_all.vendor_name) ,
		  adm_pomchchg_all.trx_ctrl_num
    FROM adm_pomchchg_all
	join adm_vend_all (nolock) on adm_pomchchg_all.vendor_code       = adm_vend_all.vendor_code
	join adm_pomchcdt (nolock) on adm_pomchchg_all.match_ctrl_int    = adm_pomchcdt.match_ctrl_int 
	left outer join glcurr_vw (nolock) on adm_pomchchg_all.nat_cur_code = glcurr_vw.currency_code
	WHERE adm_pomchchg_all.process_group_num = @batch 

   UPDATE #t1 
         set pay_to_name = appayto.pay_to_name,
             appayto_addr1  = addr1,
             appayto_addr2  = addr2,
             appayto_addr3  = addr3,
             appayto_addr4  = addr4,
             appayto_addr5  = addr5,
             appayto_addr6  = addr6
     FROM appayto,adm_pomchchg_all
     WHERE #t1.vendor_code      = appayto.vendor_code AND
           #t1.vendor_remit_to  = appayto.pay_to_code AND
           #t1.process_group_num = @batch 


exec ('select * from #t1 order by ' + @sort_by)
           
END

GO
GRANT EXECUTE ON  [dbo].[fs_match_rpt] TO [public]
GO
